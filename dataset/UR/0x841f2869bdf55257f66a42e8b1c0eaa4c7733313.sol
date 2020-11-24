 

pragma solidity ^0.4.23;

 

 
contract ERC20 {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

contract TimeLockedWallet {
                                                                                                                                            
    address public creator;                                                                                                                 
    address public owner;                                                                                                                   
    uint256 public unlockDate;                                                                                                              
    uint256 public createdAt;                                                                                                               
                                                                                                                                            
    modifier onlyOwner {                                                                                                                    
        require(msg.sender == owner);                                                                                                       
        _;                                                                                                                                  
    }                                                                                                                                       
                                                                                                                                            
    constructor(                                                                                                                            
        address _creator,                                                                                                                   
        address _owner,                                                                                                                     
        uint256 _unlockDate                                                                                                                 
    ) public {                                                                                                                              
        creator = _creator;                                                                                                                 
        owner = _owner;                                                                                                                     
        unlockDate = _unlockDate;                                                                                                           
        createdAt = now;                                                                                                                    
    }                                                                                                                                       
                                                                                                                                            
     
    function () public payable {                                                                                                            
        revert();                                                                                                                           
    }                                                                                                                                       

     
    function withdrawTokens(address _tokenContract) onlyOwner public {
       require(now >= unlockDate);
       ERC20 token = ERC20(_tokenContract);
        
       uint256 tokenBalance = token.balanceOf(this);
       token.transfer(owner, tokenBalance);
       emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

    function info() public view returns(address, address, uint256, uint256, uint256) {
        return (creator, owner, unlockDate, createdAt, address(this).balance);
    }

    event Received(address from, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}

 

contract TimeLockedWalletFactory {
 
    mapping(address => address[]) wallets;

    function getWallets(address _user) 
        public
        view
        returns(address[])
    {
        return wallets[_user];
    }

    function newTimeLockedWallet(address _owner, uint256 _unlockDate)
        payable
        public
        returns(address wallet)
    {
         
        wallet = new TimeLockedWallet(msg.sender, _owner, _unlockDate);
        
         
        wallets[msg.sender].push(wallet);

         
        if(msg.sender != _owner){
            wallets[_owner].push(wallet);
        }

         
        emit Created(wallet, msg.sender, _owner, now, _unlockDate, msg.value);
    }

     
    function () public {
        revert();
    }

    event Created(address wallet, address from, address to, uint256 createdAt, uint256 unlockDate, uint256 amount);
}