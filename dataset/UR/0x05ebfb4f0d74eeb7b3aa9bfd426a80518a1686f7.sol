 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

interface ERC20Compat {
  function transfer( address to, uint256 quantity ) external;
}

contract Ownable {
  address public owner;
  modifier isOwner {
    require( msg.sender == owner );
    _;
  }
  constructor() public { owner = msg.sender; }
  function chown( address newowner ) isOwner public { owner = newowner; }
}

contract DecentraList is Ownable {

  enum PostType { SELLING, BUYING, NOTICE }

  event ImagePosted( string   locale,
                     string   category,
                     PostType postType,
                     string   url,
                     uint256  payment );

  event TextPosted( string   locale,
                    string   category,
                    PostType postType,
                    string   text,
                    uint256  payment );

  uint256 public imageFee_;
  uint256 public textFee_;

  constructor() public {
    imageFee_ = 1 finney;
    textFee_  = 5 szabo;
  }

  function setTextFee( uint256 _tf ) isOwner public { textFee_ = _tf; }
  function setImageFee( uint256 _if ) isOwner public { imageFee_ = _if; }

  function postImage( string   _locale,
                      string   _category,
                      PostType _ptype,
                      string   _url ) public payable {

    require( msg.value >= imageFee_ );
    emit ImagePosted( _locale, _category, _ptype, _url, msg.value );
  }

  function postText( string   _locale,
                     string   _category,
                     PostType _ptype,
                     string   _txt ) public payable {

    uint256 fee = bytes(_txt).length * textFee_;
    require( msg.value >= fee );
    emit TextPosted( _locale, _category, _ptype, _txt, fee );
  }

  function retrieve( uint _amount ) isOwner public {
    owner.transfer( _amount );
  }

  function fwdTokens( address _toksca,
                      address _to,
                      uint256 _quantity ) isOwner public {
    ERC20Compat(_toksca).transfer( _to, _quantity );
  }
}

 
 
 
 
 