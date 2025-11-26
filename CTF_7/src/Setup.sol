// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;

import "./Governance.sol";

contract Setup {
    Governance public governance;

    constructor() public {
        governance = new Governance("Greeting");
    }

    function isSolved() public view returns (bool) {
        return governance.Flag();
    }
}
