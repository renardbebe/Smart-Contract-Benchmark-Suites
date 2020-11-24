 

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

contract ContributorApprover {
    KyberContributorWhitelist public list;
    mapping(address=>uint)    public participated;

    uint                      public cappedSaleStartTime;
    uint                      public openSaleStartTime;
    uint                      public openSaleEndTime;

    using SafeMath for uint;


    function ContributorApprover( KyberContributorWhitelist _whitelistContract,
                                  uint                      _cappedSaleStartTime,
                                  uint                      _openSaleStartTime,
                                  uint                      _openSaleEndTime ) {
        list = _whitelistContract;
        cappedSaleStartTime = _cappedSaleStartTime;
        openSaleStartTime = _openSaleStartTime;
        openSaleEndTime = _openSaleEndTime;

        require( list != KyberContributorWhitelist(0x0) );
        require( cappedSaleStartTime < openSaleStartTime );
        require(  openSaleStartTime < openSaleEndTime );
    }

     
    function contributorCap( address contributor ) constant returns(uint) {
        return list.getCap( contributor );
    }

    function eligible( address contributor, uint amountInWei ) constant returns(uint) {
        if( now < cappedSaleStartTime ) return 0;
        if( now >= openSaleEndTime ) return 0;

        uint cap = contributorCap( contributor );

        if( cap == 0 ) return 0;
        if( now < openSaleStartTime ) {
            uint remainedCap = cap.sub( participated[ contributor ] );

            if( remainedCap > amountInWei ) return amountInWei;
            else return remainedCap;
        }
        else {
            return amountInWei;
        }
    }

    function eligibleTestAndIncrement( address contributor, uint amountInWei ) internal returns(uint) {
        uint result = eligible( contributor, amountInWei );
        participated[contributor] = participated[contributor].add( result );

        return result;
    }

    function saleEnded() constant returns(bool) {
        return now > openSaleEndTime;
    }

    function saleStarted() constant returns(bool) {
        return now >= cappedSaleStartTime;
    }
}

contract KyberNetworkTokenSale is ContributorApprover {
    address             public admin;
    address             public kyberMultiSigWallet;
    KyberNetworkCrystal public token;
    uint                public raisedWei;
    bool                public haltSale;

    mapping(bytes32=>uint) public proxyPurchases;

    function KyberNetworkTokenSale( address _admin,
                                    address _kyberMultiSigWallet,
                                    KyberContributorWhitelist _whilteListContract,
                                    uint _totalTokenSupply,
                                    uint _premintedTokenSupply,
                                    uint _cappedSaleStartTime,
                                    uint _publicSaleStartTime,
                                    uint _publicSaleEndTime )

        ContributorApprover( _whilteListContract,
                             _cappedSaleStartTime,
                             _publicSaleStartTime,
                             _publicSaleEndTime )
    {
        admin = _admin;
        kyberMultiSigWallet = _kyberMultiSigWallet;

        token = new KyberNetworkCrystal( _totalTokenSupply,
                                         _cappedSaleStartTime,
                                         _publicSaleEndTime + 7 days,
                                         _admin );

         
        token.transfer( kyberMultiSigWallet, _premintedTokenSupply );
    }

    function setHaltSale( bool halt ) {
        require( msg.sender == admin );
        haltSale = halt;
    }

    function() payable {
        buy( msg.sender );
    }

    event ProxyBuy( bytes32 indexed _proxy, address _recipient, uint _amountInWei );
    function proxyBuy( bytes32 proxy, address recipient ) payable returns(uint){
        uint amount = buy( recipient );
        proxyPurchases[proxy] = proxyPurchases[proxy].add(amount);
        ProxyBuy( proxy, recipient, amount );

        return amount;
    }

    event Buy( address _buyer, uint _tokens, uint _payedWei );
    function buy( address recipient ) payable returns(uint){
        require( tx.gasprice <= 50000000000 wei );

        require( ! haltSale );
        require( saleStarted() );
        require( ! saleEnded() );

        uint weiPayment = eligibleTestAndIncrement( recipient, msg.value );

        require( weiPayment > 0 );

         
        if( msg.value > weiPayment ) {
            msg.sender.transfer( msg.value.sub( weiPayment ) );
        }

         
        sendETHToMultiSig( weiPayment );
        raisedWei = raisedWei.add( weiPayment );
        uint recievedTokens = weiPayment.mul( 600 );

        assert( token.transfer( recipient, recievedTokens ) );


        Buy( recipient, recievedTokens, weiPayment );

        return weiPayment;
    }

    function sendETHToMultiSig( uint value ) internal {
        kyberMultiSigWallet.transfer( value );
    }

    event FinalizeSale();
     
    function finalizeSale() {
        require( saleEnded() );
        require( msg.sender == admin );

         
        token.burn(token.balanceOf(this));

        FinalizeSale();
    }

     
     
    function emergencyDrain(ERC20 anyToken) returns(bool){
        require( msg.sender == admin );
        require( saleEnded() );

        if( this.balance > 0 ) {
            sendETHToMultiSig( this.balance );
        }

        if( anyToken != address(0x0) ) {
            assert( anyToken.transfer(kyberMultiSigWallet, anyToken.balanceOf(this)) );
        }

        return true;
    }

     
     
    function debugBuy() payable {
        require( msg.value == 123 );
        sendETHToMultiSig( msg.value );
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

contract KyberContributorWhitelist is Ownable {
     
     
    uint public slackUsersCap = 7;
    mapping(address=>uint) public addressCap;

    function KyberContributorWhitelist() {}

    event ListAddress( address _user, uint _cap, uint _time );

     
     
    function listAddress( address _user, uint _cap ) onlyOwner {
        addressCap[_user] = _cap;
        ListAddress( _user, _cap, now );
    }

     
    function listAddresses( address[] _users, uint[] _cap ) onlyOwner {
        require(_users.length == _cap.length );
        for( uint i = 0 ; i < _users.length ; i++ ) {
            listAddress( _users[i], _cap[i] );
        }
    }

    function setSlackUsersCap( uint _cap ) onlyOwner {
        slackUsersCap = _cap;
    }

    function getCap( address _user ) constant returns(uint) {
        uint cap = addressCap[_user];

        if( cap == 1 ) return slackUsersCap;
        else return cap;
    }

    function destroy() onlyOwner {
        selfdestruct(owner);
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

contract KyberNetworkCrystal is StandardToken, Ownable {
    string  public  constant name = "Kyber Network Crystal";
    string  public  constant symbol = "KNC";
    uint    public  constant decimals = 18;

    uint    public  saleStartTime;
    uint    public  saleEndTime;

    address public  tokenSaleContract;

    modifier onlyWhenTransferEnabled() {
        if( now <= saleEndTime && now >= saleStartTime ) {
            require( msg.sender == tokenSaleContract );
        }
        _;
    }

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this) );
        _;
    }

    function KyberNetworkCrystal( uint tokenTotalAmount, uint startTime, uint endTime, address admin ) {
         
        balances[msg.sender] = tokenTotalAmount;
        totalSupply = tokenTotalAmount;
        Transfer(address(0x0), msg.sender, tokenTotalAmount);

        saleStartTime = startTime;
        saleEndTime = endTime;

        tokenSaleContract = msg.sender;
        transferOwnership(admin);  
    }

    function transfer(address _to, uint _value)
        onlyWhenTransferEnabled
        validDestination(_to)
        returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        onlyWhenTransferEnabled
        validDestination(_to)
        returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

    function burn(uint _value) onlyWhenTransferEnabled
        returns (bool){
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) onlyWhenTransferEnabled
        returns (bool) {
        assert( transferFrom( _from, msg.sender, _value ) );
        return burn(_value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        token.transfer( owner, amount );
    }
}