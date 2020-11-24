 

 
 
 
 
 
 
 

 

pragma solidity ^0.4.11;

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract RKCToken is StandardToken, Ownable {
    using SafeMath for uint;

     
    string public name = "Royal Kingdom Coin";
    string public symbol = "RKC";
    uint public decimals = 18;

     
    bool public constant TEST_MODE = false;
    uint public constant atto = 1000000000000000000;
    uint public constant INITIAL_SUPPLY = 15000000 * atto;  
    address public teamWallet = 0xb79F963f200f85D0e3dD60C82ABB8F80b5869CB9;
     
    address public ico_address = 0x1c01C01C01C01c01C01c01c01c01C01c01c01c01;
    uint public constant ICO_START_TIME = 1499810400;

     
    uint public current_supply = 0;  
    uint public ico_starting_supply = 0;  
    uint public current_price_atto_tokens_per_wei = 0;  

     
    bool public preSoldSharesDistributed = false;  
    bool public isICOOpened = false;
    bool public isICOClosed = false;
     
     
     
     

     
    uint[] public premiumPacks;
    mapping(address => uint) premiumPacksPaid;

     
    event ICOOpened();
    event ICOClosed();
    event PriceChanged(uint old_price, uint new_price);
    event SupplyChanged(uint supply, uint old_supply);
    event RKCAcquired(address account, uint amount_in_wei, uint amount_in_rkc);

     

     
    function RKCToken() {
         
         
        distributePreSoldShares();

         
        current_price_atto_tokens_per_wei = calculateCurrentPrice(1);

         
        premiumPacks.length = 0;
    }

     
    function () payable {
        buy();
    }

     

     
     
     
     
    function buy() payable {
        if (msg.value == 0) throw;  

         
        if (!isICOOpened) throw;
        if (isICOClosed) throw;

         
        uint tokens = getAttoTokensAmountPerWeiInternal(msg.value);

         
        uint allowedInOneTransaction = current_supply / 100;
        if (tokens > allowedInOneTransaction) throw;

         
        if (tokens > balances[ico_address]) throw;

         
        balances[ico_address] = balances[ico_address].sub(tokens);  
        balances[msg.sender] = balances[msg.sender].add(tokens);

         
        uint old_price = current_price_atto_tokens_per_wei;
        current_price_atto_tokens_per_wei = calculateCurrentPrice(getAttoTokensBoughtInICO());
        if (current_price_atto_tokens_per_wei == 0) current_price_atto_tokens_per_wei = 1;  
        if (current_price_atto_tokens_per_wei > old_price) current_price_atto_tokens_per_wei = old_price;  

         
        if (old_price != current_price_atto_tokens_per_wei) PriceChanged(old_price, current_price_atto_tokens_per_wei);

         
        RKCAcquired(msg.sender, msg.value, tokens);
    }

     
    function calculateCurrentPrice(uint attoTokensBought) constant returns (uint result) {
         
        return (395500000 / ((attoTokensBought / atto) + 150000)).sub(136);  
    }

     

     

    function openICO() onlyOwner {
        if (isICOOpened) throw;
        if (isICOClosed) throw;
        isICOOpened = true;

        ICOOpened();
    }
    function closeICO() onlyOwner {
        if (isICOClosed) throw;
        if (!isICOOpened) throw;

        isICOOpened = false;
        isICOClosed = true;

         
        premiumPacks.length = 1;
        premiumPacks[0] = balances[ico_address];
        balances[ico_address] = 0;

        ICOClosed();
    }
    function pullEtherFromContract() onlyOwner {
         
        if (!isICOClosed) throw;

        if (!teamWallet.send(this.balance)) {
            throw;
        }
    }

     

     
     
    function distributePreSoldShares() onlyOwner {
         
        if (preSoldSharesDistributed) throw;
        preSoldSharesDistributed = true;

         
        balances[0x7A3c869603E28b0242c129440c9dD97F8A5bEe80] = 7508811 * atto;
        balances[0x24a541dEAe0Fc87C990A208DE28a293fb2A982d9] = 4025712 * atto;
        balances[0xEcF843458e76052E6363fFb78C7535Cd87AA3AB2] = 300275 * atto;
        balances[0x947963ED2da750a0712AE0BF96E08C798813F277] = 150000 * atto;
        balances[0x82Bc8452Ab76fBA446e16b57C080F5258F557734] = 150000 * atto;
        balances[0x0959Ed48d55e580BB58df6E5ee01BAa787d80848] = 90000 * atto;
        balances[0x530A8016fB5B3d7A0F92910b4814e383835Bd51E] = 75000 * atto;
        balances[0xC3e934D3ADE0Ab9F61F824a9a824462c790e47B0] = 202 * atto;
        current_supply = (7508811 + 4025712 + 300275 + 150000 + 150000 + 90000 + 75000 + 202) * atto;

         
        balances[ico_address] = INITIAL_SUPPLY.sub(current_supply);

         
        ico_starting_supply = balances[ico_address];
        current_supply = INITIAL_SUPPLY;
        SupplyChanged(0, current_supply);
    }

     

     

    function getCurrentPriceAttoTokensPerWei() constant returns (uint result) {
        return current_price_atto_tokens_per_wei;
    }
    function getAttoTokensAmountPerWeiInternal(uint value) payable returns (uint result) {
        return value * current_price_atto_tokens_per_wei;
    }
    function getAttoTokensAmountPerWei(uint value) constant returns (uint result) {
        return value * current_price_atto_tokens_per_wei;
    }
    function getSupply() constant returns (uint result) {
        return current_supply;
    }
    function getAttoTokensLeftForICO() constant returns (uint result) {
        return balances[ico_address];
    }
    function getAttoTokensBoughtInICO() constant returns (uint result) {
        return ico_starting_supply - getAttoTokensLeftForICO();
    }
    function getBalance(address addr) constant returns (uint balance) {
        return balances[addr];
    }
    function getPremiumPack(uint index) constant returns (uint premium) {
        return premiumPacks[index];
    }
    function getPremiumCount() constant returns (uint length) {
        return premiumPacks.length;
    }
    function getBalancePremiumsPaid(address account) constant returns (uint result) {
        return premiumPacksPaid[account];
    }

     

     

    function sendPremiumPack(uint amount) onlyOwner allowedPayments(msg.sender, amount) {
        premiumPacks.length += 1;
        premiumPacks[premiumPacks.length-1] = amount;
        balances[msg.sender] = balances[msg.sender].sub(amount);  
    }

    function updatePremiums(address account) private {
        if (premiumPacks.length > premiumPacksPaid[account]) {
            uint startPackIndex = premiumPacksPaid[account];
            uint finishPackIndex = premiumPacks.length - 1;
            for(uint i = startPackIndex; i <= finishPackIndex; i++) {
                if (current_supply != 0) {  
                    uint owing = balances[account] * premiumPacks[i] / current_supply;
                    balances[account] = balances[account].add(owing);
                }
            }
            premiumPacksPaid[account] = premiumPacks.length;
        }
    }

     

     

    modifier allowedPayments(address payer, uint value) {
         
        if (isICOOpened) throw;
        if (!isICOClosed) throw;

         
        uint diff = 0;
        uint allowed = 0;
        if (balances[payer] > current_supply / 100) {  
            if (block.timestamp > ICO_START_TIME) {
                diff = block.timestamp - ICO_START_TIME;
            } else {
                diff = ICO_START_TIME - block.timestamp;
            }

            allowed = (current_supply / 20) * (diff / (60 * 60 * 24 * 30));  

            if (value > allowed) throw;
        }

        _;
    }

    function transferFrom(address _from, address _to, uint _value) allowedPayments(_from, _value) {
        updatePremiums(_from);
        updatePremiums(_to);
        super.transferFrom(_from, _to, _value);
    }
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) allowedPayments(msg.sender, _value) {
        updatePremiums(msg.sender);
        updatePremiums(_to);
        super.transfer(_to, _value);
    }

}