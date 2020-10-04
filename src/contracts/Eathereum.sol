pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./RewardPool.sol";

contract Eathereum {
    using SafeMath for uint256;
    
    uint256 public _fees = 0;
    RewardPool public rewardPool;
    address payable public _owner;
    uint256 public playersPlayed = 0;
    uint256 public eatReward;
    uint256 public eatAwardLimit;
    uint256 public amountForReward;
    bool public isRewardPoolSet = false;
    uint256 public eatAwarded = 0;

    mapping(address => Player) public players;
    mapping(address => uint256) public refRewards;

    struct Player {
        string name;
        uint256 amount;
        address payable playerAddress;
        address ref;
        bool isPlaying;
    }

    event EmitPlayer(
        string name,
        uint256 amount,
        address playerAddress,
        bool isPlaying
    );

    event Transaction(
        address playerAddress,
        uint256 amount
    );

    event OwnershipTransferred(
        address indexed previousOwner, 
        address payable indexed newOwner
    );

    constructor(
        uint256 _amountForReward, 
        uint256 _eatReward, 
        uint256 _eatAwardLimit
    ) public {
        _owner = _msgSender();
        amountForReward = _amountForReward;
        eatReward = _eatReward;
        eatAwardLimit = _eatAwardLimit;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not contract owner");
        _;
    }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgValue() internal view returns (uint256) {
        return msg.value;
    }

    modifier doesPlayerExist() {
        Player memory _player = players[_msgSender()];
        require(!_player.isPlaying);
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setRewardPoolAddress(RewardPool _rewardPool) public onlyOwner {
        require(!isRewardPoolSet, 'eat address already set');
        rewardPool = _rewardPool;
        isRewardPoolSet = true;
    }

    function emitPlayer(address playerAddress) public {
        Player memory _player = players[playerAddress];
        emit EmitPlayer(_player.name, _player.amount, _player.playerAddress, _player.isPlaying);
    }

    function createPlayer(string memory _name, address _ref) payable public doesPlayerExist {
        require(bytes(_name).length > 0, "Name is required");
        require(msg.value > 0, "Amount is required");
        require(_msgSender() != address(0));
        address payable player = _msgSender();

        playersPlayed = playersPlayed.add(1);
        players[player].name = _name;
        players[player].amount = msg.value;
        players[player].playerAddress = player;
        players[player].isPlaying = true;

        if(_ref != _owner && _ref != address(0)) {
            players[player].ref = _ref;
        }
        emit EmitPlayer(_name, msg.value, player, true);
    }

    function playerEaten(
        address payable _eater, 
        address payable _eaten, 
        uint256 gas
    ) payable public onlyOwner {
        Player memory _playerEater = players[_eater];
        Player memory _playerEaten = players[_eaten];
        require(_playerEaten.amount > 0);
        uint256 fee = 0;
        if(_playerEater.amount >= _playerEaten.amount) {
            fee = _playerEaten.amount.div(10);
            uint256 feeSubAmount = fee.add(gas);
            uint256 amountForWinner = _playerEaten.amount.sub(feeSubAmount);
            _eater.transfer(amountForWinner);
            players[_eaten].amount = 0;
            if(_playerEater.ref != address(0)) {
                uint256 refFee = fee.mul(10).div(4).div(10);
                fee = fee.sub(refFee).add(gas);
                addRefReward(_playerEater.ref, refFee);
            }
            addFees(fee);
        } else {
            uint256 gasSplit = gas.div(2);
            fee = _playerEater.amount.div(10);
            uint256 feeSubAmount = fee.add(gasSplit);
            uint256 amountForLoser = _playerEaten.amount.sub(feeSubAmount).sub(_playerEater.amount);
            uint256 amountForWinner = _playerEater.amount.sub(feeSubAmount);

            uint256 transactionsFee = fee.mul(2);
            _eaten.transfer(amountForLoser);
            _eater.transfer(amountForWinner);
            _playerEaten.amount = 0;

            if(_playerEater.ref != address(0)) {
                uint256 refFee = transactionsFee.mul(10).div(4).div(10);
                addRefReward(_playerEater.ref, refFee);
                transactionsFee = transactionsFee.sub(refFee);
            }
            if(_playerEaten.ref != address(0)) {
                uint256 refFee = transactionsFee.mul(10).div(4).div(10);
                transactionsFee = transactionsFee.sub(refFee);
                addRefReward(_playerEaten.ref, refFee);
            }
            fee = fee.add(gas);
            addFees(transactionsFee);
        }
        players[_eaten].amount = 0;
        players[_eaten].isPlaying = false;
        if(
            _playerEater.amount >= amountForReward 
            && eatAwarded < eatAwardLimit
        ) {
            rewardPool.setRewards(_playerEater.playerAddress, eatReward);
            eatAwarded = eatAwarded.add(eatReward);
        }
    }

    function addFees(uint256 fee) internal {
        require(fee > 0, 'fee is lower then 0 ');
        _fees = _fees.add(fee);
    }

    function addRefReward(address _ref, uint256 _reward) internal {
        if(_reward > 0 && _ref != address(0)) {
            refRewards[_ref] = refRewards[_ref].add(_reward);
        }
    }

    function withdrawRefReward(uint256 _amount) payable public {
        require(_amount > 0);
        require(refRewards[_msgSender()] <= _amount);
        _msgSender().transfer(refRewards[_msgSender()]);
        refRewards[_msgSender()] = refRewards[_msgSender()].sub(_amount);
    }

    function pullFees() payable public onlyOwner {
        require(_fees > 0, 'no fees to pull');
        _owner.transfer(_fees);
        _fees = 0;
    }

    function playerDisconnect(address payable _disconnector) payable public onlyOwner {
        addFees(players[_disconnector].amount);
        players[_disconnector].amount = 0;
        players[_disconnector].isPlaying = false;
    }

    function playerLeave(address payable _leaver, uint256 gas) payable public onlyOwner {
        uint256 fee = players[_leaver].amount.div(10);
        uint256 subAmount = fee.add(gas);
        uint256 leaverAmount = players[_leaver].amount.sub(subAmount);
        _leaver.transfer(leaverAmount);
        if(players[_leaver].ref != address(0)) {
            uint256 refFee = fee.mul(10).div(4).div(10);
            fee = fee.sub(refFee);
            addRefReward(players[_leaver].ref, refFee);
        }
        fee = fee.add(gas);
        addFees(fee);
        players[_leaver].amount = 0;
        players[_leaver].isPlaying = false;
    }
}