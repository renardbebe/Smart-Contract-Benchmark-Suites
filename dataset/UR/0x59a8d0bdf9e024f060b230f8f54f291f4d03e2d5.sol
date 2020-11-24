 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract CHXSwap is Ownable {
    event AddressMapped(address indexed ethAddress, string chxAddress);
    event AddressMappingRemoved(address indexed ethAddress, string chxAddress);

    mapping (address => string) public mappedAddresses;

    function CHXSwap()
        public
    {
    }

    function mapAddress(string _chxAddress)
        external
    {
        address ethAddress = msg.sender;
        require(bytes(mappedAddresses[ethAddress]).length == 0);
        mappedAddresses[ethAddress] = _chxAddress;
        AddressMapped(ethAddress, _chxAddress);
    }

    function removeMappedAddress(address _ethAddress)
        external
        onlyOwner
    {
        require(bytes(mappedAddresses[_ethAddress]).length != 0);
        string memory chxAddress = mappedAddresses[_ethAddress];
        delete mappedAddresses[_ethAddress];
        AddressMappingRemoved(_ethAddress, chxAddress);
    }

     
    function drainStrayEther(uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        owner.transfer(_amount);
        return true;
    }

     
    function drainStrayTokens(ERC20Basic _token, uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        return _token.transfer(owner, _amount);
    }
}