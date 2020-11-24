 

pragma solidity 0.4.20;

contract IOwnable {
    function getOwner() public view returns (address);
    function transferOwnership(address newOwner) public returns (bool);
}

contract Ownable is IOwnable {
    address internal owner;

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner returns (bool) {
        if (_newOwner != address(0)) {
            onTransferOwnership(owner, _newOwner);
            owner = _newOwner;
        }
        return true;
    }

     
    function onTransferOwnership(address, address) internal returns (bool);
}

contract IRepPriceOracle {
    function setRepPriceInAttoEth(uint256 _repPriceInAttoEth) external returns (bool);
    function getRepPriceInAttoEth() external view returns (uint256);
}

contract RepPriceOracle is Ownable, IRepPriceOracle {
     
    uint256 private repPriceInAttoEth = 6 * 10 ** 16;

    function setRepPriceInAttoEth(uint256 _repPriceInAttoEth) external onlyOwner returns (bool) {
        repPriceInAttoEth = _repPriceInAttoEth;
        return true;
    }

    function getRepPriceInAttoEth() external view returns (uint256) {
        return repPriceInAttoEth;
    }

    function onTransferOwnership(address, address) internal returns (bool) {
        return true;
    }
}