pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";


/**
 * @title A Very Safe Lender
 */
interface ERC20Like {
    function transfer(address dst, uint qty) external returns (bool);
    function transferFrom(address src, address dst, uint qty) external returns (bool);
    function approve(address dst, uint qty) external returns (bool);
    
    function balanceOf(address who) external view returns (uint);
}

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

contract SafeLender is ReentrancyGuard {

    WETH9 public constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(){}

    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        bytes calldata data
    )
        external
        nonReentrant
    {
        uint256 balanceBefore = weth.balanceOf(address(this));
        require(borrowAmount <= balanceBefore, "Not enough tokens");
        
        (bool success,) = borrower.call(data);
        require(success, "Contract call failed");

        uint256 newBalance = weth.balanceOf(address(this));
        require(newBalance >= balanceBefore, "Please pay back the flash loan");
    }
}
