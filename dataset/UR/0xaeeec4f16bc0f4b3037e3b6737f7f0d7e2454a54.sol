 

 

pragma solidity ^0.4.18;


 
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
    uint public unlockDate;
    uint public createdAt;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function TimeLockedWallet(
        address _creator,
        address _owner,
        uint _unlockDate
    ) public {
        creator = _creator;
        owner = _owner;
        unlockDate = _unlockDate;
        createdAt = now;
    }

     
    function() payable public { 
        Received(msg.sender, msg.value);
    }

     
    function withdraw() onlyOwner public {
       require(now >= unlockDate);
        
       msg.sender.transfer(this.balance);
       Withdrew(msg.sender, this.balance);
    }

     
    function withdrawTokens(address _tokenContract) onlyOwner public {
       require(now >= unlockDate);
       ERC20 token = ERC20(_tokenContract);
        
       uint tokenBalance = token.balanceOf(this);
       token.transfer(owner, tokenBalance);
       WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    }

    function info() public view returns(address, address, uint, uint, uint) {
        return (creator, owner, unlockDate, createdAt, this.balance);
    }

    event Received(address from, uint amount);
    event Withdrew(address to, uint amount);
    event WithdrewTokens(address tokenContract, address to, uint amount);
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

    function newTimeLockedWallet(address _owner, uint _unlockDate)
        payable
        public
        returns(address wallet)
    {
         
        wallet = new TimeLockedWallet(msg.sender, _owner, _unlockDate);
        
         
        wallets[msg.sender].push(wallet);

         
         
        if(msg.sender != _owner){
            wallets[_owner].push(wallet);
        }

         
        wallet.transfer(msg.value);

         
        Created(wallet, msg.sender, _owner, now, _unlockDate, msg.value);
    }

     
    function () public {
        revert();
    }

    event Created(address wallet, address from, address to, uint createdAt, uint unlockDate, uint amount);
}