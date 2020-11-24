 

pragma solidity ^0.4.18;

 
 
 

library SafeMath {

  function mul(uint a, uint b) internal pure returns (uint) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

 
contract Ownable {

  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
     address inp_sender = msg.sender;
     bool chekk = msg.sender == owner;
    require(chekk);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

 

contract BasisIco  {

  using SafeMath for uint;
  
    string public constant name = "Basis Token";

    string public constant symbol = "BSS";

    uint32 public constant decimals = 0;  
    
    struct Investor {
        address holder;
        uint tokens;

    }
  
    Investor[] internal Cast_Arr;
     
    Investor tmp_investor;  
      
  
   
   
   
  address internal constant owner_wallet = 0x79d8af6eEA6Aeeaf7a3a92D348457a5C4f0eEe1B;
  address public constant owner = 0x79d8af6eEA6Aeeaf7a3a92D348457a5C4f0eEe1B;
  address internal constant developer = 0xf2F1A92AD7f1124ef8900931ED00683f0B3A5da7;

   
   

  uint public constant bountyPercent = 4;
  

   
   
  uint internal constant rate = 3300000000000000;
  
    uint public token_iso_price;
 
 

   
   
  uint public start_declaration = 1511384400;
   
  uint public ico_period = 15;
   
  uint public presale_finish;
   
  uint public second_round_start;
   
  uint public ico_finish = start_declaration + (ico_period * 1 days).mul(6);


   
    uint public constant hardcap = 1536000;
     
    uint public softcap = 150000;
     
    uint public bssTotalSuply;
     
    uint public weiRaised;
   
    mapping(address => uint) public ico_balances;
   
    mapping(address => uint) public ico_investor;
   
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event  Finalized();  
    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    bool RefundICO =false;
    bool isFinalized =false;
     
    mapping (address => mapping (address => uint256)) allowed;
    
 
  function BasisIco() public     {

 
    weiRaised = 0;
    bssTotalSuply = 0;
  
    
    token_iso_price = rate.mul(80).div(100); 



    presale_finish = start_declaration + (ico_period * 1 days);
    second_round_start = start_declaration + (ico_period * 1 days).mul(2);
  }
  
    modifier saleIsOn() {
      require(now > start_declaration && now < ico_finish);
      _;
    }

    modifier NoBreak() {
      require(now < presale_finish  || now > second_round_start);
      _;
    }

    modifier isUnderHardCap() {
      require (bssTotalSuply <= hardcap);
      _;
    }  
    
    modifier onlyOwner() {
         address inp_sender = msg.sender;
         bool chekk = msg.sender == owner;
        require(chekk);
    _;
     }
  
    function setPrice () public isUnderHardCap saleIsOn {
          if  (now < presale_finish ){
                
              if( bssTotalSuply > 50000 && bssTotalSuply <= 100000 ) {
                  token_iso_price = rate.mul(85).div(100);
              }
                if( bssTotalSuply > 100000 && bssTotalSuply <= 150000 ) {
                  token_iso_price = rate.mul(90).div(100);
                  }

          }
          else {
               if(bssTotalSuply <= 200000) {
                   token_iso_price = rate.mul(90).div(100);
               } else { if(bssTotalSuply <= 400000) {
                        token_iso_price = rate.mul(95).div(100);
                        }
                        else {
                        token_iso_price = rate;
                        }
                      }
           }
    } 
    
    function getActualPrice() public returns (uint) {
        setPrice ();        
        return token_iso_price;
    }  
    
     function validPurchase(uint _msg_value) internal constant returns (bool) {
     bool withinPeriod = now >= start_declaration && now <= ico_finish;
     bool nonZeroPurchase = _msg_value != 0;
     return withinPeriod && nonZeroPurchase;
   }
   
   function token_mint(address _investor, uint _tokens, uint _wei) internal {
       
       ico_balances[_investor] = ico_balances[_investor].add(_tokens);
       tmp_investor.holder = _investor;
       tmp_investor.tokens = _tokens;
       Cast_Arr.push(tmp_investor);
       ico_investor[_investor]= ico_investor[_investor].add(_wei);
   }
    
   function buyTokens() external payable saleIsOn NoBreak {
     
      
     require(validPurchase(msg.value));

     uint256 weiAmount = msg.value;

      
     uint256 tokens = weiAmount.div(token_iso_price);
     if  (now < presale_finish ){
         require ((bssTotalSuply + tokens) <= softcap);
     }
    require ((bssTotalSuply + tokens) < hardcap);
      
     weiRaised = weiRaised.add(weiAmount);

     token_mint( msg.sender, tokens, msg.value);
     TokenPurchase(msg.sender, msg.sender, weiAmount, tokens);

      
     bssTotalSuply += tokens;
    }

    
   function () external payable {
     buyTokensFor(msg.sender);
   } 

   function buyTokensFor(address beneficiary) public payable saleIsOn NoBreak {
     
     require(beneficiary != address(0));
     require(validPurchase(msg.value));

     uint256 weiAmount = msg.value;

      
     uint256 tokens = weiAmount.div(token_iso_price);
      if  (now < presale_finish ){
         require ((bssTotalSuply + tokens) <= softcap);
     }
    require ((bssTotalSuply + tokens) < hardcap);
      
     weiRaised = weiRaised.add(weiAmount);

     token_mint( beneficiary, tokens, msg.value);
     TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

      
     bssTotalSuply += tokens;
 }
 
   function extraTokenMint(address beneficiary, uint _tokens) external payable saleIsOn onlyOwner {
     
    require(beneficiary != address(0));
    require ((bssTotalSuply + _tokens) < hardcap);
    
    uint weiAmount = _tokens.mul(token_iso_price);
      
    weiRaised = weiRaised.add(weiAmount);

     token_mint( beneficiary, _tokens, msg.value);
     TokenPurchase(msg.sender, beneficiary, weiAmount, _tokens);

      
     bssTotalSuply += _tokens;
  }

  function goalReached() public constant returns (bool) {
    return bssTotalSuply >= softcap;
  }
  
  function bounty_mining () internal {
    uint bounty_tokens = bssTotalSuply.mul(bountyPercent).div(100);
    uint tmp_z = 0;
    token_mint(owner_wallet, bounty_tokens, tmp_z);
    bssTotalSuply += bounty_tokens;
    }  
  
   
  function finalization() public onlyOwner {
    require (now > ico_finish);
    if (goalReached()) {
        bounty_mining ();
        EtherTakeAfterSoftcap ();
        } 
    else {
        RefundICO = true;    
    }
    isFinalized = true;
    Finalized();
  }  

  function investor_Refund()  public {
        require (RefundICO && isFinalized);
        address investor = msg.sender;
        uint for_refund = ico_investor[msg.sender];
        investor.transfer(for_refund);

  }
  
  function EtherTakeAfterSoftcap () onlyOwner public {
      require ( bssTotalSuply >= softcap );
      uint for_developer = this.balance;
      for_developer = for_developer.mul(6).div(100);
      developer.transfer(for_developer);
      owner.transfer(this.balance);
  }

  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return ico_balances[_owner];
  }
  
   function transfer(address _to, uint256 _value) public returns (bool) {
    ico_balances[msg.sender] = ico_balances[msg.sender].sub(_value);
    ico_balances[_to] = ico_balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  } 

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
    require (_value <= _allowance);

    ico_balances[_to] = ico_balances[_to].add(_value);
    ico_balances[_from] = ico_balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  
  function approve(address _spender, uint256 _value) public returns (bool) {

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }  

  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}