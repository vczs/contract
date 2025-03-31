// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract VerifySig {
    function verify(address _siger, string memory _msg,bytes memory _sig) external pure returns (bool) {
        bytes32 ethSignMsgHash = getEthMsgHash(getMsgHash(_msg));

        return recover(ethSignMsgHash,_sig) == _siger;
    }

    function getMsgHash(string memory _msg) public pure returns (bytes32) { 
        return keccak256(abi.encodePacked(_msg));
    }

    function getEthMsgHash(bytes32 _msgHash) public pure returns (bytes32) { 
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', _msgHash));
    }

    function recover(bytes32 _ethSignMsgHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = split(_signature);
        return ecrecover(_ethSignMsgHash, v, r, s);
    }

    function split(bytes memory sig) internal pure returns (bytes32 r,bytes32 s,uint8 v) {
        require(sig.length == 65, 'invalid signature length');
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
