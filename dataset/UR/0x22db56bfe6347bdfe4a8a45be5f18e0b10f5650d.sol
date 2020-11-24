 

pragma solidity ^0.4.13;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);

     
    event Transfer(address indexed _from, address indexed _to, uint _value);
     
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);

     
    event Approval(address indexed _owner, address indexed _spender, uint _value);
     
}

contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
         
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract REKTTokenSale {
    using SafeMath for uint;

    address             public admin;
    address             public REKTMultiSigWallet;
    REKT                public token;
    bool                public haltSale;

    function REKTTokenSale( address _admin,
    address _REKTMultiSigWallet,
    REKT _token)
    {
        admin = _admin;
        REKTMultiSigWallet = _REKTMultiSigWallet;

        token = _token;
    }

    function setHaltSale( bool halt ) {
        require( msg.sender == admin );
        haltSale = halt;
    }

    function() payable {
        buy( msg.sender );
    }

    event Buy( address _buyer, uint _tokens, uint _payedWei );
    function buy( address recipient ) payable returns(uint){
        require( ! haltSale );

         
        sendETHToMultiSig( msg.value );
        uint receivedTokens = msg.value.mul( 1000 );

        assert( token.transfer( recipient, receivedTokens ) );


        Buy( recipient, receivedTokens, msg.value );

        return msg.value;
    }

    function sendETHToMultiSig( uint value ) internal {
        REKTMultiSigWallet.transfer( value );
    }

     
     
    function emergencyDrain(ERC20 anyToken) returns(bool){
        require( msg.sender == admin );

        if( this.balance > 0 ) {
            sendETHToMultiSig( this.balance );
        }

        if( anyToken != address(0x0) ) {
            assert( anyToken.transfer(REKTMultiSigWallet, anyToken.balanceOf(this)) );
        }

        return true;
    }
}

contract REKT is StandardToken, Ownable {
    string  public  constant name = "REKT";
    string  public  constant symbol = "REKT";
    uint    public  constant decimals = 18;

    address public  tokenSaleContract;

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    function REKT( uint tokenTotalAmount, address admin ) {
         
        balances[msg.sender] = tokenTotalAmount.div(2);
        balances[admin] = tokenTotalAmount.div(2);
        totalSupply = tokenTotalAmount;
        Transfer(address(0x0), msg.sender, tokenTotalAmount);

        tokenSaleContract = msg.sender;
        transferOwnership(admin);  
    }

    function transfer(address _to, uint _value)
    validDestination(_to)
    returns (bool) {
        return super.transfer(_to, _value);
    }

    function setTokenSaleContract(address _tokenSaleContract) onlyOwner {
        tokenSaleContract = _tokenSaleContract;
    }

    function transferFrom(address _from, address _to, uint _value)
    validDestination(_to)
    returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value)
    returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value)
    returns (bool) {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        token.transfer( owner, amount );
    }
}