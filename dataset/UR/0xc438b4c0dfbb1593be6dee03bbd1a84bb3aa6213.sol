 

pragma solidity ^0.4.18;


 
contract AbstractToken {

    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}


contract Owned {

    address public owner = msg.sender;
    address public potentialOwner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyPotentialOwner {
        require(msg.sender == potentialOwner);
        _;
    }

    event NewOwner(address old, address current);
    event NewPotentialOwner(address old, address potential);

    function setOwner(address _new)
        public
        onlyOwner
    {
        NewPotentialOwner(owner, _new);
        potentialOwner = _new;
    }

    function confirmOwnership()
        public
        onlyPotentialOwner
    {
        NewOwner(owner, potentialOwner);
        owner = potentialOwner;
        potentialOwner = 0;
    }
}


 
contract StandardToken is AbstractToken, Owned {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
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

}


 
 
contract SafeMath {
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

    function pow(uint a, uint b) internal returns (uint) {
        uint c = a ** b;
        assert(c >= a);
        return c;
    }
}


 
 
contract Token is StandardToken, SafeMath {

     
    uint public creationTime;

    function Token() {
        creationTime = now;
    }


     
    function transferERC20Token(address tokenAddress)
        public
        onlyOwner
        returns (bool)
    {
        uint balance = AbstractToken(tokenAddress).balanceOf(this);
        return AbstractToken(tokenAddress).transfer(owner, balance);
    }

     
    function withDecimals(uint number, uint decimals)
        internal
        returns (uint)
    {
        return mul(number, pow(10, decimals));
    }
}


 
 
contract QchainToken is Token {

     
    string constant public name = "Ethereum Qchain Token";
    string constant public symbol = "EQC";
    uint8 constant public decimals = 8;

     
    address constant public foundationReserve = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

     
    address constant public icoAllocation = 0x1111111111111111111111111111111111111111;

     
    address constant public preIcoAllocation = 0x2222222222222222222222222222222222222222;

     
    uint256 constant public startDate = 1508878800;
    uint256 constant public duration = 42 days;

     
    address public signer;

     
    address public multisig;

     
    function QchainToken(address _signer, address _multisig)
    {
         
        totalSupply = withDecimals(375000000, decimals);

         
        uint preIcoTokens = withDecimals(11500000, decimals);

         
        balances[foundationReserve] = div(mul(totalSupply, 40), 100);

         
        balances[preIcoAllocation] = preIcoTokens;

         
        balances[icoAllocation] = totalSupply - preIcoTokens - balanceOf(foundationReserve);

         
        allowed[preIcoAllocation][msg.sender] = balanceOf(preIcoAllocation);

         
        allowed[foundationReserve][msg.sender] = balanceOf(foundationReserve);

        signer = _signer;
        multisig = _multisig;
    }

    modifier icoIsActive {
        require(now >= startDate && now < startDate + duration);
        _;
    }

    modifier icoIsCompleted {
        require(now >= startDate + duration);
        _;
    }

     
    function invest(address investor, uint256 tokenPrice, uint256 value, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        public
        icoIsActive
        payable
    {
         
        require(sha256(uint(investor) << 96 | tokenPrice) == hash);

         
        require(ecrecover(hash, v, r, s) == signer);

         
         
        require(sub(value, msg.value) <= withDecimals(5, 15));

         
        uint256 tokensNumber = div(withDecimals(value, decimals), tokenPrice);

         
        require(balances[icoAllocation] >= tokensNumber);

         
        require(multisig.send(msg.value));

         
        balances[icoAllocation] -= tokensNumber;
        balances[investor] += tokensNumber;
        Transfer(icoAllocation, investor, tokensNumber);
    }

     
    function confirmOwnership()
        public
        onlyPotentialOwner
    {
         
         
        allowed[foundationReserve][potentialOwner] = balanceOf(foundationReserve);
        allowed[preIcoAllocation][potentialOwner] = balanceOf(preIcoAllocation);

         
         
        allowed[foundationReserve][owner] = 0;
        allowed[preIcoAllocation][owner] = 0;

         
        super.confirmOwnership();
    }

     
    function withdrawFromReserve(uint amount)
        public
        onlyOwner
    {
         
        require(transferFrom(foundationReserve, multisig, amount));
    }

     
    function changeMultisig(address _multisig)
        public
        onlyOwner
    {
        multisig = _multisig;
    }

     
    function burn()
        public
        onlyOwner
        icoIsCompleted
    {
        totalSupply = sub(totalSupply, balanceOf(icoAllocation));
        balances[icoAllocation] = 0;
    }
}