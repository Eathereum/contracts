pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EAT.sol";

contract RewardPool is Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) public rewards;
    address public devAddress;
    EAT public eat;

    constructor(
        EAT _eat,
        address _devAddress
    ) public {
        eat = _eat;
        devAddress = _devAddress;
    }

    function setRewards(address _to, uint256 _amount ) public onlyOwner {
        require(_amount > 0);
        rewards[_to] = rewards[_to].add(_amount);
    }
    
    function withdraw() payable public {
        uint256 reward = rewards[msg.sender];
        require(reward > 0);
        safeEatTransfer(msg.sender, reward);
        rewards[msg.sender] = 0;
    }

    function safeEatTransfer(address _to, uint256 _amount) internal {
        uint256 eatBal = eat.balanceOf(address(this));
        if(eatBal > 0) {
            if (_amount > eatBal) {
                eat.transfer(_to, eatBal);
            } else {
                eat.transfer(_to, _amount);
            }
        }
    }
}