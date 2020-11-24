 

pragma solidity ^0.4.18;

  

 
contract ERC223ReceivingContract {

     
     
     
     
    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

 
contract Token {
     

     
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function burn(uint num) public;

     
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _burner, uint _value);

     
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract PhiToken is Token {

     

     
     
    string constant public name = "PHI Token";
    string constant public symbol = "PHI";
    uint8 constant public decimals = 18;
    using SafeMath for uint;
    uint constant multiplier = 10 ** uint(decimals);

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
    uint256 public totalSupply =  24157817 * multiplier;

     
    bool initialTokensAssigned = false;

     
    address public PRE_ICO_ADDR;
    address public ICO_ADDR;

     
    address public WALLET_ADDR;

     
    uint public lockTime;

     
     
     
    modifier onlyIfLockTimePassed () {
        require(now > lockTime || (msg.sender == PRE_ICO_ADDR || msg.sender == ICO_ADDR));
        _;
    }

     
    event Deployed(uint indexed _total_supply);

     
     
     
     
     
     
     
     
    function PhiToken(
        address ico_address,
        address pre_ico_address,
        address wallet_address,
        uint _lockTime)
        public
    {
         
        require(ico_address != 0x0);
        require(pre_ico_address != 0x0);
        require(wallet_address != 0x0);
        require(ico_address != pre_ico_address && wallet_address != ico_address);
        require(initialTokensAssigned == false);
         
        require(_lockTime > now);
        lockTime = _lockTime;

        WALLET_ADDR = wallet_address;

         
        require(totalSupply > multiplier);

         
        uint initAssign = 0;

         
        initAssign += assignTokens(ico_address, 7881196 * multiplier);
        ICO_ADDR = ico_address;
         
        initAssign += assignTokens(pre_ico_address, 3524578 * multiplier);
        PRE_ICO_ADDR = pre_ico_address;
         
        initAssign += assignTokens(wallet_address, 9227465 * multiplier);

         
        uint presaleTokens = 0;
        presaleTokens += assignTokens(address(0x72B16DC0e5f85aA4BBFcE81687CCc9D6871C2965), 230387 * multiplier);
        presaleTokens += assignTokens(address(0x7270cC02d88Ea63FC26384f5d08e14EE87E75154), 132162 * multiplier);
        presaleTokens += assignTokens(address(0x25F92f21222969BB0b1f14f19FBa770D30Ff678f), 132162 * multiplier);
        presaleTokens += assignTokens(address(0xAc99C59D3353a34531Fae217Ba77139BBe4eDBb3), 443334 * multiplier);
        presaleTokens += assignTokens(address(0xbe41D37eB2d2859143B9f1D29c7BC6d7e59174Da), 970826500000000000000000);  
        presaleTokens += assignTokens(address(0x63e9FA0e43Fcc7C702ed5997AfB8E215C5beE3c9), 970826500000000000000000);  
        presaleTokens += assignTokens(address(0x95c67812c5C41733419aC3b1916d2F282E7A15A4), 396486 * multiplier);
        presaleTokens += assignTokens(address(0x1f5d30BB328498fF6E09b717EC22A9046C41C257), 20144 * multiplier);
        presaleTokens += assignTokens(address(0x0a1ac564e95dAEDF8d454a3593b75CCdd474fc42), 19815 * multiplier);
        presaleTokens += assignTokens(address(0x0C5448D5bC4C40b4d2b2c1D7E58E0541698d3e6E), 19815 * multiplier);
        presaleTokens += assignTokens(address(0xFAe11D521538F067cE0B13B6f8C929cdEA934D07), 75279 * multiplier);
        presaleTokens += assignTokens(address(0xEE51304603887fFF15c6d12165C6d96ff0f0c85b), 45949 * multiplier);
        presaleTokens += assignTokens(address(0xd7Bab04C944faAFa232d6EBFE4f60FF8C4e9815F), 6127 * multiplier);
        presaleTokens += assignTokens(address(0x603f39C81560019c8360F33bA45Bc1E4CAECb33e), 45949 * multiplier);
        presaleTokens += assignTokens(address(0xBB5128f1093D1aa85F6d7D0cC20b8415E0104eDD), 15316 * multiplier);
        
        initialTokensAssigned = true;

        Deployed(totalSupply);

        assert(presaleTokens == 3524578 * multiplier);
        assert(totalSupply == (initAssign.add(presaleTokens)));
    }

     
     
     
     
     
    function assignTokens (address addr, uint amount) internal returns (uint) {
        require(addr != 0x0);
        require(initialTokensAssigned == false);
        balances[addr] = amount;
        Transfer(0x0, addr, balances[addr]);
        return balances[addr];
    }

     
     
     
     
    function burn(uint256 _value) public onlyIfLockTimePassed {
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        require(totalSupply >= _value);

        uint pre_balance = balances[msg.sender];
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
        Transfer(burner, 0x0, _value);
        assert(balances[burner] == pre_balance.sub(_value));
    }

     

     
     
     
     
     
    function transfer(address _to, uint256 _value) public onlyIfLockTimePassed returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to].add(_value) >= balances[_to]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _value,
        bytes _data)
        public
        onlyIfLockTimePassed
        returns (bool)
    {
        require(transfer(_to, _value));

        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        return true;
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        onlyIfLockTimePassed
        returns (bool)
    {
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to].add(_value) >= balances[_to]);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _value) public onlyIfLockTimePassed returns (bool) {
        require(_spender != 0x0);

         
         
         
         
        require(_value == 0 || allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
     
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

}