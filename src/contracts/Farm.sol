//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./EAT.sol";

contract Farm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint; 
        uint256 lastRewardBlock;  
        uint256 accEatPerShare;
        bool locked;
    }
    EAT public eat;
    address public dev_address;
    uint256 public startBlock;
    uint256 public eatPerBlock;
    uint256 public bonusEndBlock;
    uint256 public constant BONUS_MULTIPLIER = 1;
    uint256 public totalAllocPoint = 0;
    bool public didSetEatAddress = false;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolEvent (
        IERC20 lpToken,
        uint256 allocPoint, 
        uint256 accEatPerShare,
        bool locked
    );
    event NumberEvent(uint256 numb);

    constructor(
        address _dev_address,
        uint256 _eatPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        dev_address = _dev_address;
        eatPerBlock = _eatPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
    }

    function setEatAddress(EAT _eat) public onlyDev {
        require(!didSetEatAddress, 'Eat contract address is already set');
        eat = _eat;
        didSetEatAddress = true;
    }

    function updateEatPerBlock(uint256 _eatPerBlock) public onlyDev {
        require(_eatPerBlock > 0, 'Must distribute EAT');
        eatPerBlock = _eatPerBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        emit PoolEvent(_lpToken,_allocPoint,0, true);

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accEatPerShare: 0,
            locked: true
        }));
    }

    // View pending EATER for user
    function pendingEat(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accEatPerShare = pool.accEatPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 eatReward = multiplier.mul(eatPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accEatPerShare = accEatPerShare.add(eatReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accEatPerShare).div(1e12).sub(user.rewardDebt);
    }

   function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending = 0;
        if (user.amount > 0) {
            pending = user.amount.mul(pool.accEatPerShare).div(1e12).sub(user.rewardDebt);
        } 
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accEatPerShare).div(1e12).sub(pending);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(!pool.locked, "EAT currently locked");
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accEatPerShare).div(1e12).sub(user.rewardDebt);
        safeEatTransfer(msg.sender, pending, pool.locked);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accEatPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawLPTokens(uint256 _pid, uint256 _amount) public { // withdraw lp tokens without waiting for EATER lockdown
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        updatePool(_pid);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function safeEatTransfer(address _to, uint256 _amount, bool _locked) internal {
        if(!_locked) {
            uint256 eatBal = eat.balanceOf(address(this));
            if (_amount > eatBal) {
                eat.transfer(_to, eatBal);
            } else {
                eat.transfer(_to, _amount);
            }
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 eatReward = multiplier.mul(eatPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accEatPerShare = pool.accEatPerShare.add(eatReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updateDevAddress(address _dev_address) public onlyDev {
        dev_address = _dev_address;
    }

    function unlockPool(uint256 _pid) public onlyDev {
        require(poolInfo[_pid].locked, 'withdrawing is not locked');
        poolInfo[_pid].locked = false;
    }

    modifier onlyDev()  {
        require(msg.sender == dev_address, "Not dev address");
        _;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }
}