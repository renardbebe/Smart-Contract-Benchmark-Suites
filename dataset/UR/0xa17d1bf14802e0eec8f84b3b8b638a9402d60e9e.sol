 

pragma solidity ^0.4.10;

contract IERC20Token {
    function totalSupply() public constant returns ( uint256 supply ) { supply; }
    function balanceOf( address _owner ) public constant returns ( uint256 balance ) { _owner; balance; }
    function allowance( address _owner, address _spender ) public constant returns ( uint256 remaining ) { _owner; _spender; remaining; }

  function transfer( address _to, uint256 _value ) public returns ( bool success );
  function transferFrom( address _from, address _to, uint256 _value ) public returns ( bool success );
  function approve( address _spender, uint256 _value ) public returns ( bool success );
}
contract RegaUtils {
  modifier validAddress( address _address ) {
    require( _address != 0x0 );
    _;
  }

   
  function safeAdd( uint256 x, uint256 y ) internal returns( uint256 ) {
    uint256 z = x + y;
    assert( z >= x );
    return z;
  }

  function safeSub( uint256 x, uint256 y ) internal returns( uint256 ) {
    assert( x >= y);
    return x - y;
  }
}
contract ERC20Token is IERC20Token, RegaUtils {
  uint256 public totalSupply = 0;
  mapping( address => uint256 ) public balanceOf;
  mapping( address => mapping( address => uint256 ) ) public allowance;

  event Transfer( address indexed _from, address indexed _to, uint256 _value );
  event Approval( address indexed _owner, address indexed _spender, uint256 _value );

  function transfer( address _to, uint256 _value ) validAddress( _to )
    returns( bool success )
  {
    balanceOf[ msg.sender ] = safeSub( balanceOf[ msg.sender ], _value );
    balanceOf[ _to ] = safeAdd( balanceOf[ _to ], _value );
    Transfer( msg.sender, _to, _value );
    return true;
  }

  function transferFrom( address _from, address _to, uint256 _value ) validAddress( _from ) validAddress( _to )
    returns( bool success )
  {
    allowance[ _from ][ msg.sender ] = safeSub( allowance[ _from ][ msg.sender ], _value );
    balanceOf[ _from] = safeSub( balanceOf[_from], _value );
    balanceOf[ _to] = safeAdd( balanceOf[_to], _value );
    Transfer( _from, _to, _value );
    return true;
  }

  function approve( address _spender, uint256 _value ) validAddress( _spender )
    returns( bool success)
  {
    require( _value == 0 || allowance[ msg.sender ][ _spender ] == 0 );

    allowance[ msg.sender ][ _spender ] = _value;
    Approval( msg.sender, _spender, _value );
    return true;
  }

}
contract RSTBase is ERC20Token {
  address public board;
  address public owner;

  address public votingData;
  address public tokenData;
  address public feesData;

  uint256 public reserve;
  uint32  public crr;          
  uint256 public weiForToken;  
  uint8   public totalAccounts;

  modifier boardOnly() {
    require(msg.sender == board);
    _;
  }
}
contract TokenControllerBase is RSTBase {
  function init() public;
  function isSellOpen() public constant returns(bool);
  function isBuyOpen() public constant returns(bool);
  function sell(uint value) public;
  function buy() public payable;
  function addToReserve() public payable;
}

contract VotingControllerBase is RSTBase {
  function voteFor() public;
  function voteAgainst() public;
  function startVoting() public;
  function stopVoting() public;
  function getCurrentVotingDescription() public constant returns (bytes32 vd) ;
}

contract FeesControllerBase is RSTBase {
  function init() public;
  function withdrawFee() public;
  function calculateFee() public;
  function addPayee( address payee ) public;
  function removePayee( address payee ) public;
  function setRepayment( ) payable public;
}
contract RiskSharingToken is RSTBase {
  string public constant version = "0.1";
  string public constant name = "REGA Risk Sharing Token";
  string public constant symbol = "RST";
  uint8 public constant decimals = 10;

  TokenControllerBase public tokenController;
  VotingControllerBase public votingController;
  FeesControllerBase public feesController;

  modifier ownerOnly() {
    require( msg.sender == owner );
    _;
  }

  modifier boardOnly() {
    require( msg.sender == board );
    _;
  }

  modifier authorized() {
    require( msg.sender == owner || msg.sender == board);
    _;
  }


  function RiskSharingToken( address _board ) {
    board = _board;
    owner = msg.sender;
    tokenController = TokenControllerBase(0);
    votingController = VotingControllerBase(0);
    weiForToken = uint(10)**(18-1-decimals);  
    reserve = 0;
    crr = 20;
    totalAccounts = 0;
  }

  function() payable {

  }

  function setTokenController( TokenControllerBase tc, address _tokenData ) public boardOnly {
    tokenController = tc;
    if( _tokenData != address(0) )
      tokenData = _tokenData;
    if( tokenController != TokenControllerBase(0) )
      if( !tokenController.delegatecall(bytes4(sha3("init()"))) )
        revert();
  }

 
  function setVotingController( VotingControllerBase vc ) public boardOnly {
    votingController = vc;
  }

  function startVoting( bytes32   ) public boardOnly validAddress(votingController) {
    if( !votingController.delegatecall(msg.data) )
      revert();
  }

  function stopVoting() public boardOnly validAddress(votingController) {
    if( !votingController.delegatecall(msg.data) )
      revert();
  }

  function voteFor() public validAddress(votingController) {
    if( !votingController.delegatecall(msg.data) )
      revert();
  }

  function voteAgainst() public validAddress(votingController) {
    if( !votingController.delegatecall(msg.data) )
      revert();
  }

 
  function buy() public payable validAddress(tokenController) {
    if( !tokenController.delegatecall(msg.data) )
      revert();
  }

  function sell( uint   ) public validAddress(tokenController) {
    if( !tokenController.delegatecall(msg.data) )
      revert();
  }

  function addToReserve( ) public payable validAddress(tokenController) {
    if( !tokenController.delegatecall(msg.data) )
      revert();
  }

 
  function withdraw( uint256 amount ) public boardOnly {
    require(safeSub(this.balance, amount) >= reserve);
    board.transfer( amount );
  }

  function issueToken( address  , uint256   ) public authorized {
    if( !tokenController.delegatecall(msg.data) )
      revert();
  }

  function issueTokens( uint256[]   ) public ownerOnly {
    if( !tokenController.delegatecall(msg.data) )
      revert();
  }

   

  function setFeesController( FeesControllerBase fc ) public boardOnly {
    feesController = fc;
    if( !feesController.delegatecall(bytes4(sha3("init()"))) )
      revert();
  }

  function withdrawFee() public validAddress(feesController) {
      if( !feesController.delegatecall(msg.data) )
        revert();
  }

  function calculateFee() public validAddress(feesController) {
      if( !feesController.delegatecall(msg.data) )
        revert();
  }
  function addPayee( address   ) public validAddress(feesController) {
      if( !feesController.delegatecall(msg.data) )
        revert();
  }
  function removePayee( address   ) public validAddress(feesController) {
      if( !feesController.delegatecall(msg.data) )
        revert();
  }
  function setRepayment( ) payable public validAddress(feesController) {
      if( !feesController.delegatecall(msg.data) )
        revert();
  }
}