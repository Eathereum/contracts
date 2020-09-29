pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./EAT.sol";

contract Eathereum {
    using SafeMath for uint256;
    
    uint256 public _fees = 0;
    EAT public eat;
    address payable public _owner;
    uint256 public playersPlayed = 0;
    uint256 public eatToMint;
    uint256 public eatMintLimit;
    uint256 public amountForMint;
    bool public isEatAddressSet = false;
    uint256 public eatMinted = 0;

    mapping(address => Player) public players;

    struct Player {
        string name;
        uint256 amount;
        address payable playerAddress;
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
        uint256 _amountForMint, 
        uint256 _eatToMint, 
        uint256 _eatMintLimit
    ) public {
        _owner = _msgSender();
        amountForMint = _amountForMint;
        eatToMint = _eatToMint;
        eatMintLimit = _eatMintLimit;
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

    function setEatAddress(EAT _eat) public onlyOwner {
        require(!isEatAddressSet, 'eat address already set');
        eat = _eat;
        isEatAddressSet = true;
    }

    function emitPlayer(address playerAddress) public {
        Player memory _player = players[playerAddress];
        emit EmitPlayer(_player.name, _player.amount, _player.playerAddress, _player.isPlaying);
    }

    function createPlayer(string memory _name) payable public doesPlayerExist {
        require(bytes(_name).length > 0, "Name is required");
        require(msg.value > 0, "Amount is required");
        playersPlayed = playersPlayed.add(1);
        players[_msgSender()] = Player(_name, msg.value, _msgSender(), true);
        emit EmitPlayer(_name, msg.value, _msgSender(), true);
    }

    function playerEaten(
        address payable _eater, 
        address payable _eaten, 
        uint256 gas
    ) payable public onlyOwner {
        Player memory _player_eater = players[_eater];
        Player memory _player_eaten = players[_eaten];
        require(_player_eaten.amount > 0);

        if(_player_eater.amount >= _player_eaten.amount) {
            uint256 fee = _player_eaten.amount
            .div(10)
            .add(gas);
            uint256 amountForWinner = _player_eaten.amount.sub(fee);
            _eater.transfer(amountForWinner);
            addFees(fee);
            players[_eaten].amount = 0;
        } else {
            uint256 gasSplit = gas.div(2);
            uint256 fee = _player_eater.amount.div(10).add(gasSplit);
            uint256 amountForLoser = _player_eaten.amount
            .sub(fee)
            .sub(_player_eater.amount);
            uint256 amountForWinner = _player_eater.amount.sub(fee);
            uint transactionsFee = fee.mul(2);
            _eaten.transfer(amountForLoser);
            _eater.transfer(amountForWinner);
            addFees(transactionsFee);
            _player_eaten.amount = 0;
        }   
        players[_eaten].amount = 0;
        players[_eaten].isPlaying = false;
        if(
            _player_eater.amount >= amountForMint 
            && eatMinted < eatMintLimit
        ) {
            eat.mint(_player_eater.playerAddress, eatToMint);
            eatMinted += eatToMint;
        }
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

    function playerDisconnect(address payable _disconnector) payable public onlyOwner {
        addFees(players[_disconnector].amount);
        players[_disconnector].amount = 0;
        players[_disconnector].isPlaying = false;
    }

    function playerLeave(address payable _leaver, uint256 gas) payable public onlyOwner {
        uint256 fee = players[_leaver].amount.div(10).add(gas);
        uint leaverAmount = players[_leaver].amount.sub(fee);
        addFees(fee);
        _leaver.transfer(leaverAmount);
        players[_leaver].amount = 0;
        players[_leaver].isPlaying = false;
    }
}