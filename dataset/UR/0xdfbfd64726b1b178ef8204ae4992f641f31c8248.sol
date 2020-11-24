 

pragma solidity ^0.4.11;

 


 
library SafeMath {

     
     function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
     }

     
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

}


 
contract Owned {

     
    address public owner;
     
    address public newOwner;

     
    event OwnershipTransferred(address indexed _from, address indexed _to);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() {
         
        if (msg.sender == newOwner && owner != newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


 
contract ERC20Token {
     
    using SafeMath for uint;

     
    uint256 public totalSupply = 0;

     
    mapping(address => uint256) public balanceOf;

     
    mapping(address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balanceOf[msg.sender] >= _amount                 
            && _amount > 0                                  
            && balanceOf[_to] + _amount > balanceOf[_to]      
        ) {
            balanceOf[msg.sender] -= _amount;
            balanceOf[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowance[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        if (balanceOf[_from] >= _amount                   
            && allowance[_from][msg.sender] >= _amount     
            && _amount > 0                               
            && balanceOf[_to] + _amount > balanceOf[_to]   
        ) {
            balanceOf[_from] -= _amount;
            allowance[_from][msg.sender] -= _amount;
            balanceOf[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
}


contract EloPlayToken is ERC20Token, Owned {

     
    string public constant symbol = "ELT";
    string public constant name = "EloPlayToken";
    uint8 public constant decimals = 18;

     
    address public TARGET_ADDRESS;

     
    address public TARGET_TOKENS_ADDRESS;

     
    uint256 public START_TS;
    uint256 public END_TS;

     
    uint256 public CAP;

     
    uint256 public USDETHRATE;

     
    bool public halted;

     
    uint256 public totalEthers;

     
    event TokensBought(address indexed buyer, uint256 ethers,
        uint256 new_ether_balance, uint256 tokens, uint256 target_address_tokens,
        uint256 new_total_supply, uint256 buy_price);

     
    event FundTransfer(address backer, uint amount, bool isContribution);


     
    function EloPlayToken(uint256 _start_ts, uint256 _end_ts, uint256 _cap, address _target_address,  address _target_tokens_address, uint256 _usdethrate) {
        START_TS        = _start_ts;
        END_TS          = _end_ts;
        CAP             = _cap;
        USDETHRATE      = _usdethrate;
        TARGET_ADDRESS  = _target_address;
        TARGET_TOKENS_ADDRESS  = _target_tokens_address;
    }

     
    function updateCap(uint256 _cap, uint256 _usdethrate) onlyOwner {
         
        require(!halted);
         
        require(now < START_TS);
        CAP = _cap;
        USDETHRATE = _usdethrate;
    }

     
    function totalUSD() constant returns (uint256) {
        return totalEthers * USDETHRATE;
    }

     
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(now);
    }

     
    function buyPriceAt(uint256 _at) constant returns (uint256) {
        if (_at < START_TS) {
            return 0;
        } else if (_at < START_TS + 3600) {
             
            return 12000;
        } else if (_at < START_TS + 3600 * 24) {
             
            return 11500;
        } else if (_at < START_TS + 3600 * 24 * 7) {
             
            return 11000;
        } else if (_at < START_TS + 3600 * 24 * 7 * 2) {
             
            return 10500;
        } else if (_at <= END_TS) {
             
            return 10000;
        } else {
            return 0;
        }
    }

     
    function halt() onlyOwner {
        require(!halted);
        halted = true;
    }

     
    function unhalt() onlyOwner {
        require(halted);
        halted = false;
    }

     
    function addPrecommitment(address _participant, uint256 _balance, uint256 _ethers) onlyOwner {
        require(now < START_TS);
         
         
        require(_balance >= 1 ether);

         
        uint additional_tokens = _balance / 70 * 30;

        balanceOf[_participant] = balanceOf[_participant].add(_balance);
        balanceOf[TARGET_TOKENS_ADDRESS] = balanceOf[TARGET_TOKENS_ADDRESS].add(additional_tokens);

        totalSupply = totalSupply.add(_balance);
        totalSupply = totalSupply.add(additional_tokens);

         
        totalEthers = totalEthers.add(_ethers);

        Transfer(0x0, _participant, _balance);
        Transfer(0x0, TARGET_TOKENS_ADDRESS, additional_tokens);
    }

     
    function () payable {
        proxyPayment(msg.sender);
    }

     
    function proxyPayment(address _participant) payable {
         
        require(!halted);
         
        require(now >= START_TS);
         
        require(now <= END_TS);
         
        require(totalEthers < CAP);
         
        require(msg.value >= 0.1 ether);

         
        totalEthers = totalEthers.add(msg.value);
         
        require(totalEthers < CAP + 0.1 ether);

         
        uint256 _buyPrice = buyPrice();

         
         
        uint tokens = msg.value * _buyPrice;

         
        require(tokens > 0);
         
         
         
        uint additional_tokens = tokens * 30 / 70;

         
        totalSupply = totalSupply.add(tokens);
        totalSupply = totalSupply.add(additional_tokens);

         
        balanceOf[_participant] = balanceOf[_participant].add(tokens);
        balanceOf[TARGET_TOKENS_ADDRESS] = balanceOf[TARGET_TOKENS_ADDRESS].add(additional_tokens);

         
        TokensBought(_participant, msg.value, totalEthers, tokens, additional_tokens,
            totalSupply, _buyPrice);
        FundTransfer(_participant, msg.value, true);
        Transfer(0x0, _participant, tokens);
        Transfer(0x0, TARGET_TOKENS_ADDRESS, additional_tokens);

         
        TARGET_ADDRESS.transfer(msg.value);
    }

     
    function transfer(address _to, uint _amount) returns (bool success) {
         
        require(now > END_TS || totalEthers >= CAP);
         
        return super.transfer(_to, _amount);
    }

     
    function transferFrom(address _from, address _to, uint _amount)
            returns (bool success) {
         
        require(now > END_TS || totalEthers >= CAP);
         
        return super.transferFrom(_from, _to, _amount);
    }

     
    function transferAnyERC20Token(address _tokenAddress, uint _amount)
      onlyOwner returns (bool success) {
        return ERC20Token(_tokenAddress).transfer(owner, _amount);
    }
}