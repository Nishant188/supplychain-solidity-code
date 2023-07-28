// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../Library.sol";

interface IStakeHolderRegistration {

    function getRole(address account)
        external
        view
        returns (Types.StakeHolder);
}
