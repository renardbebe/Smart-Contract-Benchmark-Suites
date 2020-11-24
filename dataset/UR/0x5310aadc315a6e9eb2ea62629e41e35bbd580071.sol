 

pragma solidity ^0.4.0;

   
 
 
 contract Lockable {  
     uint public creationTime;
     bool public tokenSwapLock; 
     
     address public dev;
 
      
      
     modifier isTokenSwapOn { 
         if (tokenSwapLock) throw; 
        _;
     }
     
   
     
    modifier onlyDev{ 
       if (msg.sender != dev) throw; 
      _;
   }

     function Lockable() { 
       dev = msg.sender; 
     } 
 } 
 

 

 contract ERC20 { 
     function totalSupply() constant returns (uint); 
     function balanceOf(address who) constant returns (uint); 
     function allowance(address owner, address spender) constant returns (uint); 
 

     function transfer(address to, uint value) returns (bool ok); 
     function transferFrom(address from, address to, uint value) returns (bool ok); 
     function approve(address spender, uint value) returns (bool ok); 
 
     event Transfer(address indexed from, address indexed to, uint value); 
     event Approval(address indexed owner, address indexed spender, uint value); 
 } 
 
 
 contract Consulteth is ERC20, Lockable { 
 

   mapping( address => uint ) _balances; 
   mapping( address => mapping( address => uint ) ) _approvals; 
   
   uint public foundationAsset;
   uint public CTX_Cap;
   uint _supply; 
   
   address public wallet_Mini_Address;
   address public wallet_Address;
   
   uint public factorial_ICO;
   
   event TokenMint(address newTokenHolder, uint amountOfTokens); 
   event TokenSwapOver(); 
 
   modifier onlyFromMiniWallet { 
       if (msg.sender != wallet_Mini_Address) throw;
      _;
   }
   
   modifier onlyFromWallet { 
       if (msg.sender != wallet_Address) throw; 
      _;
   } 
 
  
 
   function Consulteth(uint preMine, uint cap_CTX) { 
     _balances[msg.sender] = preMine; 
     foundationAsset = preMine;
     CTX_Cap = cap_CTX;
     
     _supply += preMine;  
      
   } 
 
 
   function totalSupply() constant returns (uint supply) { 
     return _supply; 
   } 


 
   function balanceOf( address who ) constant returns (uint value) { 
     return _balances[who]; 
   } 
 
 
   function allowance(address owner, address spender) constant returns (uint _allowance) { 
     return _approvals[owner][spender]; 
   } 
 
 
    
   function safeToAdd(uint a, uint b) internal returns (bool) { 
     return (a + b >= a && a + b >= b); 
   } 
 
 
   function transfer(address to, uint value) isTokenSwapOn returns (bool ok) { 
 
 
     if( _balances[msg.sender] < value ) { 
         throw; 
     } 
     if( !safeToAdd(_balances[to], value) ) { 
         throw; 
     } 
 
 
     _balances[msg.sender] -= value; 
     _balances[to] += value; 
     Transfer( msg.sender, to, value ); 
     return true; 
   } 
 
 
   function transferFrom(address from, address to, uint value) isTokenSwapOn returns (bool ok) { 
      
     if( _balances[from] < value ) { 
         throw; 
     } 
      
     if( _approvals[from][msg.sender] < value ) { 
         throw; 
     } 
     if( !safeToAdd(_balances[to], value) ) { 
         throw; 
     } 
      
     _approvals[from][msg.sender] -= value; 
     _balances[from] -= value; 
     _balances[to] += value; 
     Transfer( from, to, value ); 
     return true; 
   } 
 
   function approve(address spender, uint value) 
     isTokenSwapOn 
     returns (bool ok) { 
     _approvals[msg.sender][spender] = value; 
     Approval( msg.sender, spender, value ); 
     return true; 
   } 
 
 
   function kickStartMiniICO(address ico_Mini_Wallet) onlyDev  { 
    if (ico_Mini_Wallet == address(0x0)) throw; 
          
    if (wallet_Mini_Address != address(0x0)) throw; 
         wallet_Mini_Address = ico_Mini_Wallet;
         
         creationTime = now; 
         tokenSwapLock = true;  
   }
 
    
    
   
   function preICOSwapRate() constant returns(uint) { 
       if (creationTime + 1 weeks > now) { 
           return 1000; 
       } 
       else if (creationTime + 3 weeks > now) { 
           return 850; 
       } 
        
       else { 
           return 0; 
       } 
   } 
   
 
   
    
    
    
    
   
function mintMiniICOTokens(address newTokenHolder, uint etherAmount) onlyFromMiniWallet
    external { 
 
 
         uint tokensAmount = preICOSwapRate() * etherAmount; 
         
         if(!safeToAdd(_balances[newTokenHolder],tokensAmount )) throw; 
         if(!safeToAdd(_supply,tokensAmount)) throw; 
 
 
         _balances[newTokenHolder] += tokensAmount; 
         _supply += tokensAmount; 
 
 
         TokenMint(newTokenHolder, tokensAmount); 
   }
   
 
    

   function disableMiniSwapLock() onlyFromMiniWallet
     external { 
         tokenSwapLock = false; 
         TokenSwapOver(); 
   }    
  


function kickStartICO(address ico_Wallet, uint mint_Factorial) onlyDev  { 
    if (ico_Wallet == address(0x0)) throw; 
          
    if (wallet_Address != address(0x0)) throw; 
         
         wallet_Address = ico_Wallet;
         factorial_ICO = mint_Factorial;
         
         creationTime = now; 
         tokenSwapLock = true;  
   }
 
  
   function ICOSwapRate() constant returns(uint) { 
       if (creationTime + 1 weeks > now) { 
           return factorial_ICO; 
       } 
       else if (creationTime + 2 weeks > now) { 
           return (factorial_ICO - 30); 
       } 
       else if (creationTime + 4 weeks > now) { 
           return (factorial_ICO - 70); 
       } 
       else { 
           return 0; 
       } 
   } 
 

 
    
    
    
    
   function mintICOTokens(address newTokenHolder, uint etherAmount) onlyFromWallet
    external { 
 
 
         uint tokensAmount = ICOSwapRate() * etherAmount; 

         if((_supply + tokensAmount) > CTX_Cap) throw;
         
         if(!safeToAdd(_balances[newTokenHolder],tokensAmount )) throw; 
         if(!safeToAdd(_supply,tokensAmount)) throw; 
 
 
         _balances[newTokenHolder] += tokensAmount; 
         _supply += tokensAmount; 
 
 
         TokenMint(newTokenHolder, tokensAmount); 
   } 
 
 
    
    
   function disableICOSwapLock() onlyFromWallet
     external { 
         tokenSwapLock = false; 
         TokenSwapOver(); 
   } 
 }