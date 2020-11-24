 

 

pragma solidity ^0.4.15;

contract Owned {
  address public ownerA;  
  bool    public pausedB;

   
   
  function Owned() {
    ownerA = msg.sender;
  }

   
   
  modifier IsOwner {
    require(msg.sender == ownerA);
    _;
  }

  modifier IsActive {
    require(!pausedB);
    _;
  }

   
   
  event LogOwnerChange(address indexed PreviousOwner, address NewOwner);
  event LogPaused();
  event LogResumed();

   
   
   
  function ChangeOwner(address vNewOwnerA) IsOwner {
    require(vNewOwnerA != address(0)
         && vNewOwnerA != ownerA);
    LogOwnerChange(ownerA, vNewOwnerA);
    ownerA = vNewOwnerA;
  }

   
  function Pause() IsOwner {
    pausedB = true;  
    LogPaused();
  }

   
  function Resume() IsOwner {
    pausedB = false;  
    LogResumed();
  }
}  


 
 

 

 

 
 

 
 
 

contract DSMath {
   

  function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
    assert((z = x + y) >= x);
  }

  function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
    assert((z = x - y) <= x);
  }

  function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
    z = x * y;
    assert(x == 0 || z / x == y);
  }

   
   
   
   

   
   
  function subMaxZero(uint256 x, uint256 y) constant internal returns (uint256 z) {
    if (y > x)
      z = 0;
    else
      z = x - y;
  }
}

 

 

 

contract ERC20Token is Owned, DSMath {
   
  bool public constant isEIP20Token = true;  
  uint public totalSupply;      
  bool public saleInProgressB;  

  mapping(address => uint) internal iTokensOwnedM;                  
  mapping(address => mapping (address => uint)) private pAllowedM;  

   
   
   
   
  event Transfer(address indexed src, address indexed dst, uint wad);

   
   
  event Approval(address indexed Sender, address indexed Spender, uint Wad);

   
   
   
   
   
   
  function balanceOf(address guy) public constant returns (uint) {
    return iTokensOwnedM[guy];
  }

   
   
  function allowance(address guy, address spender) public constant returns (uint) {
    return pAllowedM[guy][spender];
  }

   
   
  modifier IsTransferOK(address src, address dst, uint wad) {
    require(!saleInProgressB           
         && !pausedB                   
         && iTokensOwnedM[src] >= wad  
       
         && dst != src                 
         && dst != address(this)       
         && dst != ownerA);            
    _;
  }

   
   
   
   
   
  function transfer(address dst, uint wad) IsTransferOK(msg.sender, dst, wad) returns (bool) {
    iTokensOwnedM[msg.sender] -= wad;  
    iTokensOwnedM[dst] = add(iTokensOwnedM[dst], wad);
    Transfer(msg.sender, dst, wad);
    return true;
  }

   
   
   
   
   
  function transferFrom(address src, address dst, uint wad) IsTransferOK(src, dst, wad) returns (bool) {
    require(pAllowedM[src][msg.sender] >= wad);  
    iTokensOwnedM[src]         -= wad;  
    pAllowedM[src][msg.sender] -= wad;  
    iTokensOwnedM[dst] = add(iTokensOwnedM[dst], wad);
    Transfer(src, dst, wad);
    return true;
  }

   
   
   
   
  function approve(address spender, uint wad) IsActive returns (bool) {
     
     
     
     
     
     
    pAllowedM[msg.sender][spender] = wad;
    Approval(msg.sender, spender, wad);
    return true;
  }
}  

 

 

contract PacioToken is ERC20Token {
   
   
   
  string public constant name   = "Pacio Token";
  string public constant symbol = "PIOE";
  uint8  public constant decimals = 12;
  uint   public tokensIssued;            
  uint   public tokensAvailable;         
  uint   public contributors;            
  uint   public founderTokensAllocated;  
  uint   public founderTokensVested;     
  uint   public foundationTokensAllocated;  
  uint   public foundationTokensVested;     
  bool   public icoCompleteB;            
  address private pFounderToksA;         
  address private pFoundationToksA;      

   
   
  event LogIssue(address indexed Dst, uint Picos);
  event LogSaleCapReached(uint TokensIssued);  
  event LogIcoCompleted();
  event LogBurn(address Src, uint Picos);
  event LogDestroy(uint Picos);

   
   

   
   

   
   
   
  function Initialise(address vNewOwnerA) {  
    require(totalSupply == 0);           
    super.ChangeOwner(vNewOwnerA);       
    founderTokensAllocated    = 10**20;  
    foundationTokensAllocated = 10**20;  
     
    totalSupply           = 10**21;  
    iTokensOwnedM[ownerA] = 10**21;
    tokensAvailable       = 8*(10**20);  
     
    Transfer(0x0, ownerA, 10**21);  
  }

   
   
  function Mint(uint picos) IsOwner {
    totalSupply           = add(totalSupply,           picos);
    iTokensOwnedM[ownerA] = add(iTokensOwnedM[ownerA], picos);
    tokensAvailable = subMaxZero(totalSupply, tokensIssued + founderTokensAllocated + foundationTokensAllocated);
     
    Transfer(0x0, ownerA, picos);  
  }

   
   
  function PrepareForSale() IsOwner {
    require(!icoCompleteB);  
    saleInProgressB = true;  
  }

   
   
   
  function ChangeOwner(address vNewOwnerA) {  
    transfer(vNewOwnerA, iTokensOwnedM[ownerA]);  
    super.ChangeOwner(vNewOwnerA);  
  }

   
   
   

   
   
   
   
  function Issue(address dst, uint picos) IsOwner IsActive returns (bool) {
    require(saleInProgressB       
         && iTokensOwnedM[ownerA] >= picos  
       
         && dst != address(this)  
         && dst != ownerA);       
    if (iTokensOwnedM[dst] == 0)
      contributors++;
    iTokensOwnedM[ownerA] -= picos;  
    iTokensOwnedM[dst]     = add(iTokensOwnedM[dst], picos);
    tokensIssued           = add(tokensIssued,       picos);
    tokensAvailable    = subMaxZero(tokensAvailable, picos);  
    LogIssue(dst, picos);                                     
    return true;
  }

   
   
   
  function SaleCapReached() IsOwner IsActive {
    saleInProgressB = false;  
    LogSaleCapReached(tokensIssued);
  }

   
   
   
   
  function IcoCompleted() IsOwner IsActive {
    require(!icoCompleteB);
    saleInProgressB = false;  
    icoCompleteB    = true;
    LogIcoCompleted();
  }

   
   
   
   
   
  function SetFFSettings(address vFounderTokensA, address vFoundationTokensA, uint vFounderTokensAllocation, uint vFoundationTokensAllocation) IsOwner {
    if (vFounderTokensA    != address(0)) pFounderToksA    = vFounderTokensA;
    if (vFoundationTokensA != address(0)) pFoundationToksA = vFoundationTokensA;
    if (vFounderTokensAllocation > 0)    assert((founderTokensAllocated    = vFounderTokensAllocation)    >= founderTokensVested);
    if (vFoundationTokensAllocation > 0) assert((foundationTokensAllocated = vFoundationTokensAllocation) >= foundationTokensVested);
    tokensAvailable = totalSupply - founderTokensAllocated - foundationTokensAllocated - tokensIssued;
  }

   
   
   
   
   
  function VestFFTokens(uint vFounderTokensVesting, uint vFoundationTokensVesting) IsOwner IsActive {
    require(icoCompleteB);  
    if (vFounderTokensVesting > 0) {
      assert(pFounderToksA != address(0));  
      assert((founderTokensVested  = add(founderTokensVested,          vFounderTokensVesting)) <= founderTokensAllocated);
      iTokensOwnedM[ownerA]        = sub(iTokensOwnedM[ownerA],        vFounderTokensVesting);
      iTokensOwnedM[pFounderToksA] = add(iTokensOwnedM[pFounderToksA], vFounderTokensVesting);
      LogIssue(pFounderToksA,          vFounderTokensVesting);
      tokensIssued = add(tokensIssued, vFounderTokensVesting);
    }
    if (vFoundationTokensVesting > 0) {
      assert(pFoundationToksA != address(0));  
      assert((foundationTokensVested  = add(foundationTokensVested,          vFoundationTokensVesting)) <= foundationTokensAllocated);
      iTokensOwnedM[ownerA]           = sub(iTokensOwnedM[ownerA],           vFoundationTokensVesting);
      iTokensOwnedM[pFoundationToksA] = add(iTokensOwnedM[pFoundationToksA], vFoundationTokensVesting);
      LogIssue(pFoundationToksA,       vFoundationTokensVesting);
      tokensIssued = add(tokensIssued, vFoundationTokensVesting);
    }
     
  }

   
   
   
  function Burn(address src, uint picos) IsOwner IsActive {
    require(icoCompleteB);
    iTokensOwnedM[src] = subMaxZero(iTokensOwnedM[src], picos);
    tokensIssued       = subMaxZero(tokensIssued, picos);
    totalSupply        = subMaxZero(totalSupply,  picos);
    LogBurn(src, picos);
     
  }

   
   
   
  function Destroy(uint picos) IsOwner IsActive {
    require(icoCompleteB);
    totalSupply     = subMaxZero(totalSupply,     picos);
    tokensAvailable = subMaxZero(tokensAvailable, picos);
    LogDestroy(picos);
  }

   
   
   
   
  function() {
    revert();  
  }
}  