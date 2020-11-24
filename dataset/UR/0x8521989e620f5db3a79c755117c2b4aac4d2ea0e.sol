 

pragma solidity 0.5.4;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract EthOwl is Ownable {
  uint256 public price = 2e16;

  event Hoot(address addr, string endpoint);

  function adjustPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function purchase(address _addr, string memory _endpoint) public payable {
    require(msg.value >= price);
    emit Hoot(_addr, _endpoint);
  }

  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }
}