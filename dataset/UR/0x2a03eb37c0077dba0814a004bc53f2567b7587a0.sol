 

 

pragma solidity ^0.5.0;

/* Importing from 'URL(https: 


library solstragglers {
  function shittyRandom() internal view returns ( uint number ) {
    number = uint( blockhash( block.number - 1 ) );  	   
  }
}
/* End importing from 'URL(https: 


contract ERC20 {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
 
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Quip {

  event QuipAdded( address indexed quipper, string quip );
  event VoterRegistered( address indexed voter );
  event VoteUpdated( address indexed voter, address indexed quipper, uint256 indexed quipIndex, string quip );
  event QuipPaid( address indexed voter, address indexed quipper, uint256 indexed quipIndex, string quip, address payoutToken, uint256 payout );

  string[]                   _quips;
  address[]                  _quippers;
  address[]                  _voters;
  mapping (address=>bool)    _voted;
  mapping (address=>uint256) _votes;

  
   

  function quipCount()
    public
    view
    returns( uint256 count ) {
    count = _quips.length;
  }

  function getQuip(uint256 i)
    public
    view
    returns( string memory quip, address quipper ) {
    quip    = _quips[i];
    quipper = _quippers[i];
  }

  function hasVoted( address voter )
    public
    view
    returns ( bool voted ) {
    voted = _voted[voter];
  }

  function currentVote( address voter )
    public
    view
    returns( uint256 index ) {
    require( _voted[voter] );
    index = _votes[voter];
  }

  function uniformRandomQuip()
    public
    view
    returns( string memory quip, address quipper ) {
    uint256 quipIndex = solstragglers.shittyRandom() % _quips.length;
    quip    = _quips[ quipIndex ];
    quipper = _quippers[ quipIndex ];
  }

  function voteWeightedRandomQuip()
    public
    view
    returns( string memory quip, address quipper ) {
    ( , uint256 quipIndex ) = drawQuipper();
    quip    = _quips[quipIndex];
    quipper = _quippers[ quipIndex ];
  }
  

   

  function addQuip( string memory quip )
    public
    returns( uint256 index ) {
    _quips.push( quip );
    _quippers.push( msg.sender );
    index = _quips.length - 1;

    emit QuipAdded( msg.sender, quip );
  }

   
  function vote( uint256 index ) 
    public {
    if (! _voted[msg.sender]) {  
      _voters.push( msg.sender );
      _voted[msg.sender] = true;
      emit VoterRegistered( msg.sender );
    }
    address quipper = _quippers[index];
    require( msg.sender != quipper, "Quippers are disallowed from voting for their own quips." );
    _votes[msg.sender] = index;
    emit VoteUpdated( msg.sender, quipper, index, _quips[index] ); 
  }

  function payout( address token, uint256 amount )
    public
    payable {
    ( address voter, uint256 quipIndex ) = drawQuipper();
    address quipper = _quippers[quipIndex];
    doPayout( quipper, token, amount );
    emit QuipPaid( voter, quipper, quipIndex, _quips[quipIndex], token, amount );    
  }

   
  function doPayout( address recipient, address token, uint256 amount )
    private {
    require( token == address(0) || msg.value == 0, "Pay either in Ether, or pay with only a token, not both." );
    if ( token == address(0) ) {
      require( msg.value >= amount, "Send enough ether to make your payout, if you are sending Ether." );
      address payable payableRecipient = address(uint160(recipient));
      payableRecipient.transfer( amount );
      uint256 change = msg.value - amount;
      if ( change > 0 ) {
	msg.sender.transfer( change );
      }
    }
    else {
      ERC20 erc20 = ERC20(token);
      require( erc20.allowance( msg.sender, address(this) ) >= amount, "If you are paying in a token, this contract must be allowed to spend the amount you wish to pay on your behalf." );
      erc20.transferFrom( msg.sender, recipient, amount );
    }
  }

  function drawQuipper()
    private
    view
    returns( address voter, uint256 quipIndex ) {
    voter     = _voters[ solstragglers.shittyRandom() % _voters.length ];
    quipIndex = _votes[voter];
  }
}