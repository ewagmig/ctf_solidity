pragma solidity ^0.8.0;
import "./SafeLender.sol";


contract Setup{

    WETH9 public constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    SafeLender public safeLender; 

    constructor() payable{
        weth.deposit{value: msg.value}();
        safeLender = new SafeLender();
        weth.transfer(address(safeLender), weth.balanceOf((address(this))));
    }

    function isSolved() public view returns (bool){
        return weth.balanceOf(address(safeLender))==0;
    }
}