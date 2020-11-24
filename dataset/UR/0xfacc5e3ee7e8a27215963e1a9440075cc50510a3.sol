 

pragma solidity ^0.4.4;

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && (balances[_to] + _value) > balances[_to] && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to] && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract IAHCToken is StandardToken {

    string public constant name   = "IAHC";
    string public constant symbol = "IAHC";

    uint8 public constant decimals = 8;
    uint  public constant decimals_multiplier = 100000000;

    address public constant ESCROW_WALLET = 0x3D7FaD8174dac0df6a0a3B473b9569f7618d07E2;

    uint public constant icoSupply          = 500000000 * decimals_multiplier;  
    uint public constant icoTokensPrice     = 142000;                           
    uint public constant icoMinCap          = 100   ether;
    uint public constant icoMaxCap          = 7000  ether;

    uint public constant whiteListMinAmount = 0.50  ether;
    uint public constant preSaleMinAmount   = 0.25  ether;
    uint public constant crowdSaleMinAmount = 0.10  ether;

    address public icoOwner;
    uint public icoLeftSupply  = icoSupply;  
    uint public icoSoldCap     = 0;          

    uint public whiteListTime         = 1519084800;  
    uint public preSaleListTime       = 1521590400;  
    uint public crowdSaleTime         = 1524355200;  
    uint public crowdSaleEndTime      = 1526947200;  
    uint public icoEndTime            = 1529712000;  
    uint public guarenteedPaybackTime = 1532304000;  

    mapping(address => bool) public whiteList;
    mapping(address => uint) public icoContributions;

    function IAHCToken(){
        icoOwner = msg.sender;
        balances[icoOwner] = 2000000000 * decimals_multiplier - icoSupply;  
        totalSupply = 2000000000 * decimals_multiplier;
    }

    modifier onlyOwner() {
        require(msg.sender == icoOwner);
        _;
    }

     
    function icoEndUnfrozeTokens() public onlyOwner() returns(bool) {
        require(now >= icoEndTime && icoLeftSupply > 0);

        balances[icoOwner] += icoLeftSupply;
        icoLeftSupply = 0;
    }

     
    function minCapFail() public {
        require(now >= icoEndTime && icoSoldCap < icoMinCap);
        require(icoContributions[msg.sender] > 0 && balances[msg.sender] > 0);

        uint tokens = balances[msg.sender];
        balances[icoOwner] += tokens;
        balances[msg.sender] -= tokens;
        uint contribution = icoContributions[msg.sender];
        icoContributions[msg.sender] = 0;

        Transfer(msg.sender, icoOwner, tokens);

        msg.sender.transfer(contribution);
    }

     
    function getCurrentStageDiscount() public constant returns (uint) {
        uint discount = 0;
        if (now >= icoEndTime && now < preSaleListTime) {
            discount = 40;
        } else if (now < crowdSaleTime) {
            discount = 28;
        } else if (now < crowdSaleEndTime) {
            discount = 10;
        }
        return discount;
    }

    function safePayback(address receiver, uint amount) public onlyOwner() {
        require(now >= guarenteedPaybackTime);
        require(icoSoldCap < icoMinCap);

        receiver.transfer(amount);
    }

     
    function countTokens(uint paid, address sender) public constant returns (uint) {
        uint discount = 0;
        if (now < preSaleListTime) {
            require(whiteList[sender]);
            require(paid >= whiteListMinAmount);
            discount = 40;
        } else if (now < crowdSaleTime) {
            require(paid >= preSaleMinAmount);
            discount = 28;
        } else if (now < crowdSaleEndTime) {
            require(paid >= crowdSaleMinAmount);
            discount = 10;
        }

        uint tokens = paid / icoTokensPrice;
        if (discount > 0) {
            tokens = tokens / (100 - discount) * 100;
        }
        return tokens;
    }

     
    function () public payable {
        contribute();
    }

    function contribute() public payable {
        require(now >= whiteListTime && now < icoEndTime && icoLeftSupply > 0);

        uint tokens = countTokens(msg.value, msg.sender);
        uint payback = 0;
        if (icoLeftSupply < tokens) {
             
            payback = msg.value - (msg.value / tokens) * icoLeftSupply;
            tokens = icoLeftSupply;
        }
        uint contribution = msg.value - payback;

        icoLeftSupply                -= tokens;
        balances[msg.sender]         += tokens;
        icoSoldCap                   += contribution;
        icoContributions[msg.sender] += contribution;

        Transfer(icoOwner, msg.sender, tokens);

        if (icoSoldCap >= icoMinCap) {
            ESCROW_WALLET.transfer(this.balance);
        }
        if (payback > 0) {
            msg.sender.transfer(payback);
        }
    }


     
    function addToWhitelist(address _participant) public onlyOwner() returns(bool) {
        if (whiteList[_participant]) {
            return true;
        }
        whiteList[_participant] = true;
        return true;
    }
    function removeFromWhitelist(address _participant) public onlyOwner() returns(bool) {
        if (!whiteList[_participant]) {
            return true;
        }
        whiteList[_participant] = false;
        return true;
    }

}