// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.9.0;

import "../Library.sol";

interface IRestrictions {
    function add(Types.Stakeholder memory user) external;

    function has(Types.StakeHolder role, address account)
        external
        view
        returns (bool);

    function isStakeHolderExists(address account) external view returns (bool);
}
