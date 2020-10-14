pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EAT is ERC20("Eathereum","EAT"), Ownable {
    uint256 private _limit;
    constructor(uint256 limit) public {
        _limit = limit;
    }

    function limit() public view returns(uint256) {
        return _limit;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 newTotalSupply = supply.add(_amount);
        require(newTotalSupply <= _limit, "total supply limit reached");
        _mint(_to, _amount);
    }


}