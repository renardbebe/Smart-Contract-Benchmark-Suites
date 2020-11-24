 

pragma solidity 0.5.8;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract BawSwapContract{
    
    ERC20 public token;
    address public owner;
    uint public bb;
    
     
    constructor(ERC20 _token) public {
        token = _token;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    
    event OwnerChanged(address oldOwner, address newOwner);
    
     
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(msg.sender, owner);
    }
    
    event Swaped(uint tokenAmount, string BNB_Address);
    
     
    function swap(uint tokenAmount, string memory BNB_Address) public returns(bool) {
        
        bool success = token.transferFrom(msg.sender, owner, tokenAmount);
        
        if(!success) {
            revert("Transfer of tokens to Swap contract failed.");
        }
        
        emit Swaped(tokenAmount, BNB_Address);
        
        return true;
        
    }
    
}