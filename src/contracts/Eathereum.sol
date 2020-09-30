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

    struct Player {
        string name;
        uint256 currentStake;
        uint256 amount;
        uint256 debt;
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

    function createPlayer(string memory _name) payable public doesPlayerExist {
        require(bytes(_name).length > 0, "Name is required");
        require(msg.value > 0, "Amount is required");
        playersPlayed = playersPlayed.add(1);
        players[_msgSender()].name = _name;
        players[_msgSender()].amount = players[_msgSender()].amount.add(msg.value);
        players[_msgSender()].currentStake = msg.value;
        
        players[_msgSender()].isPlaying = true;
        emit EmitPlayer(_name, msg.value, _msgSender(), true);
    }

    function playerEaten(
        address _eater, 
        address _eaten, 
        uint256 gas
    ) public onlyOwner {
        Player memory _player_eater = players[_eater];
        Player memory _player_eaten = players[_eaten];
        require(_player_eaten.currentStake > 0);

        if(_player_eater.currentStake >= _player_eaten.currentStake) {
            uint256 fee = _player_eaten.currentStake
                .div(10)
                .add(gas);
            uint256 amountForWinner = _player_eaten.currentStake.sub(fee);
            addWinnings(_eater, amountForWinner);
            addDebt(_eaten, _player_eaten.currentStake);
            addFees(fee);
        } else {
            uint256 gasSplit = gas.div(2);
            uint256 fee = _player_eater.currentStake.div(10).add(gasSplit);
            uint256 amountForWinner = _player_eater.currentStake.sub(fee);
            uint transactionsFee = fee.mul(2);

            addWinnings(_eater, amountForWinner);
            addDebt(_eaten, _player_eater.currentStake);
            addFees(transactionsFee);
        }
        players[_eaten].isPlaying = false;
        players[_eaten].currentStake = 0;
        if(
            _player_eater.currentStake >= amountForReward 
            && eatAwarded < eatAwardLimit
        ) {
            rewardPool.setRewards(_eater, eatReward);
            eatAwarded = eatAwarded.add(eatReward);
        }
    }

    function playerBalance(address _playerAddress) public view returns(uint256){
        Player memory _player = players[_playerAddress];
        uint256 _amount = _player.amount.sub(_player.debt);
        return _amount;
    }

    function addWinnings(address _to, uint256 _amount) internal {
        require(_to != address(this));
        require(_amount > 0);
        players[_to].amount = players[_to].amount.add(_amount);
    }

    function addDebt(address _to, uint256 _debt) internal {
        require(_to != address(this));
        require(_debt > 0);
        players[_to].debt = players[_to].debt.add(_debt);
    }

    function withdraw(uint256 _amount) payable public {
        address payable _to = _msgSender();
        uint256 _amountAvailble = players[_to].amount.sub(players[_to].debt);
        require(_amount > 0);
        require(_amountAvailble >= _amount);
        require(!players[_to].isPlaying);
        require(players[_to].currentStake == 0);
        _to.transfer(_amountAvailble);
        addDebt(_to, _amountAvailble);

    }

    function addFees(uint256 fee) private {
        require(fee > 0, 'fee is lower then 0 ');
        _fees = _fees.add(fee);
    }

    function pullFees() payable public onlyOwner {
        require(_fees > 0, 'no fees to pull');
        _owner.transfer(_fees);
        _fees = 0;
    }

    function playerDisconnect(address _disconnector) public onlyOwner {
        addFees(players[_disconnector].currentStake);
        addDebt(_disconnector, players[_disconnector].currentStake);

        players[_disconnector].currentStake = 0;
        players[_disconnector].isPlaying = false;
    }

    function playerLeave(address _leaver, uint256 gas) public onlyOwner {
        uint256 fee = players[_leaver].currentStake.div(10).add(gas);

        addFees(fee);
        addDebt(_leaver, fee);

        players[_leaver].currentStake = 0;
        players[_leaver].isPlaying = false;
    }
}