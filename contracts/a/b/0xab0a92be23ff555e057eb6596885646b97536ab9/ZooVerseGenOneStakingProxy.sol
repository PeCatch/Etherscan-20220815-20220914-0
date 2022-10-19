// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ZooVerseGenOneStaking {
    function isStakedGenOne(address owner) external view returns (bool);
}

contract ZooVerseGenOneStakingProxy {
    function balanceOf(address owner) public view returns (uint256) {
        bool isStaked = ZooVerseGenOneStaking(address(0x9b9bc763A2E115cee8A75bCd1Eef433795A1A22b)).isStakedGenOne(owner);
        if (isStaked) {
            return 1;
        } else {
            return 0;
        }
    }
}