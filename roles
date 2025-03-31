// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract AccessController {
    event GrantedRole(bytes32 indexed role,address indexed account);
    event RevokedRole(bytes32 indexed role,address indexed account);

    // 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    // 0x2db9fd3d099848027c2383d0a083396f6c41510d7acfd92adc99b6cffcf31e96
    bytes32 private constant USER = keccak256(abi.encodePacked("USER"));

    mapping(bytes32 => mapping(address => bool)) private roles;

    constructor(){
        _grantedRole(ADMIN, msg.sender);
    }

    function grantedRole(bytes32 role, address account) external onlyRole(ADMIN) {
        _grantedRole(role,account);
        emit GrantedRole(role, account);
    }

    function removeRole(bytes32 role, address account) external onlyRole(ADMIN){
        _removeRole(role,account);
        emit RevokedRole(role, account);
    }

    function queryRole(bytes32 role, address account) external view returns (bool) {
        return roles[role][account];
    }

    function _grantedRole(bytes32 role, address account) internal {
        roles[role][account] = true;
    }
    
    function _removeRole(bytes32 role, address account) internal {
        roles[role][account] = false;
    }

    modifier onlyRole(bytes32 _role) {
        require(roles[_role][msg.sender],"access denied");_;
    }

}
 
