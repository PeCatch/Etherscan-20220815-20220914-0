// SPDX-License-Identifier: MIT
// https://etherscan.io/address/0x3ce3b6d9372a4d761172a89cf0139129309fa0ae#code

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ECDSA.sol";

interface WhitelistableI {
    function changeAdmin(address _admin) external;
    function invalidateHash(bytes32 _hash) external;
    function invalidateHashes(bytes32[] calldata _hashes) external;
}

/**
 * @title Eliptic curve signature operations
 *
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 *
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 *
 */

abstract contract Whitelistable is WhitelistableI, Ownable {
    using ECDSA for bytes32;

    address public whitelistAdmin;

    // True if the hash has been invalidated
    mapping(bytes32 => bool) public invalidHash;

    event AdminUpdated(address indexed newAdmin);

    modifier validAdmin(address _admin) {
        require(_admin != address(0x0));
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == whitelistAdmin);
        _;
    }

    modifier isWhitelisted(bytes32 _hash, bytes memory _sig) {
        bool check = checkWhitelisted(_hash, _sig);
        require(checkWhitelisted(_hash, _sig));
        _;
    }

    /// @dev Constructor for Whitelistable contract
    /// @param _admin the address of the admin that will generate the signatures
    constructor(address _admin) validAdmin(_admin) {
        whitelistAdmin = _admin;        
    }

    /// @dev Updates whitelistAdmin address 
    /// @dev Can only be called by the current owner
    /// @param _admin the new admin address
    function changeAdmin(address _admin)
        external
        override
        onlyOwner
        validAdmin(_admin)
    {
        emit AdminUpdated(_admin);
        whitelistAdmin = _admin;
    }

    // @dev blacklists the given address to ban them from contributing
    // @param _contributor Address of the contributor to blacklist 
    function invalidateHash(bytes32 _hash) external override onlyAdmin {
        invalidHash[_hash] = true;
    }

    function invalidateHashes(bytes32[] memory _hashes) external override onlyAdmin {
        for (uint i = 0; i < _hashes.length; i++) {
            invalidHash[_hashes[i]] = true;
        }
    }

    /// @dev Checks if a hash has been signed by the whitelistAdmin
    /// @param _rawHash The hash that was used to generate the signature
    /// @param _sig The EC signature generated by the whitelistAdmin
    /// @return Was the signature generated by the admin for the hash?
    function checkWhitelisted(
        bytes32 _rawHash,
        bytes memory _sig
    )
        public
        view
        returns(bool)
    {
        bytes32 hash = _rawHash.toEthSignedMessageHash();
        address hashAddr = hash.recover(_sig);
        bool validHash = invalidHash[_rawHash];
        return !validHash && whitelistAdmin == hashAddr;
    }
}