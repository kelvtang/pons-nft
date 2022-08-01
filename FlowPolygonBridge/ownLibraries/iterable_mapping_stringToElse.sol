// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/stringUtils.sol";

library IterableMapping {
    /*
        Attempt to create a datatype which mimimcs the classic dictionary.
        Aims to replace the hashmaps of solidity.
    */

    struct IndexValue {
        uint256 keyIndex;
        uint256 value;
    }
    struct KeyFlag {
        string key;
        bool deleted;
    }
    struct itmap {
        mapping(string => IndexValue) data;
        KeyFlag[] keys;
        uint256 size;
    }

    function getKeyExist(itmap storage self, string calldata key)
        public
        view
        returns (uint256, bool)
    {
        for (uint256 i = 0; i < self.keys.length; i++) {
            if (StringUtils.equal(self.keys[i].key, key)) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function insertEntry(
        itmap storage self,
        string calldata key,
        uint256 value // to be store
    ) public returns (uint256) {
        (uint256 keyIndex, bool keyExists) = getKeyExist(self, key);
        if (keyExists) {
            if (!self.keys[uint256(keyIndex)].deleted) {
                uint256 oldValue = self.data[key].value;
                self.data[key].value = value;
                return oldValue;
            } else {
                self.keys[uint256(keyIndex)].deleted = false;
                IndexValue memory ih2;
                ih2.keyIndex = keyIndex;
                ih2.value = value; // to be store
                self.data[key] = ih2;
                return 0;
            }
        }
        KeyFlag memory newKey;
        newKey.key = key;
        newKey.deleted = false;
        self.keys.push(newKey);
        self.size = self.size + 1;
        IndexValue memory ih;
        ih.keyIndex = self.size - 1;
        ih.value = value; // to be store
        self.data[key] = ih;

        return 0;
    }

    function readEntry(itmap storage self, string calldata key)
        public
        view
        returns (uint256, bool)
    {
        (uint256 keyIndex, bool keyExists) = getKeyExist(self, key);
        if (keyExists) {
            if (!self.keys[uint256(keyIndex)].deleted) {
                return (self.data[key].value, true);
            }
        }
        return (0, false);
    }

    function deleteEntry(itmap storage self, string calldata key) public {
        (uint256 keyIndex, bool keyExists) = getKeyExist(self, key);
        if (keyExists) {
            if (!self.keys[uint256(keyIndex)].deleted) {
                self.keys[uint256(keyIndex)].deleted = true;
                delete self.data[key];
            }
        }
    }
}
