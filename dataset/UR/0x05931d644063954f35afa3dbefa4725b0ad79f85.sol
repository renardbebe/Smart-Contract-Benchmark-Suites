 

pragma solidity ^0.5.11;

interface Unisocks {
    function changeURI(address _newURI) external;
    function changeMinter(address _minter) external;
    function mint(address _to) external returns (bool);
}

contract UnisocksController {
    Unisocks public unisocks;
    mapping (address => bool) public owners;

    modifier ensureCallerIsOwner() {
        require(owners[msg.sender], "Caller is not an owner.");
        _;
    }

    constructor () public {
        unisocks = Unisocks(0x65770b5283117639760beA3F867b69b3697a91dd);
        owners[msg.sender] = true;
    }

    function _addOwner(address newOwner) private {
        owners[newOwner] = true;
    }

    function addOwner(address newOwner) public ensureCallerIsOwner {
        _addOwner(newOwner);
    }

    function addOwners(address[] memory newOwners) public ensureCallerIsOwner {
        for (uint i; i < newOwners.length; i++) {
            _addOwner(newOwners[i]);
        }
    }

    function _removeOwner(address currentOwner) private {
        owners[currentOwner] = false;
    }

    function removeOwner(address currentOwner) public ensureCallerIsOwner {
        _removeOwner(currentOwner);
    }

    function removeOwners(address[] memory currentOwners) public ensureCallerIsOwner {
        for (uint i; i < currentOwners.length; i++) {
            _removeOwner(currentOwners[i]);
        }
    }

    function changeURI(address newURI) public ensureCallerIsOwner {
        unisocks.changeURI(newURI);
    }

    function changeMinter(address minter) public ensureCallerIsOwner {
        unisocks.changeMinter(minter);
    }

    function _mint(address to) private {
        require(unisocks.mint(to), 'Minting was unsuccessful.');
    }

    function mint(address to) public ensureCallerIsOwner {
        _mint(to);
    }

    function mint(address[] memory tos) public ensureCallerIsOwner {
        for (uint i; i < tos.length; i++) {
            _mint(tos[i]);
        }
    }
}