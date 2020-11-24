 

pragma solidity 0.4.25;

 

interface ERC777Token {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function granularity() external view returns (uint256);

  function defaultOperators() external view returns (address[]);
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;

  function send(address to, uint256 amount, bytes holderData) external;
  function operatorSend(address from, address to, uint256 amount, bytes holderData, bytes operatorData) external;

  function burn(uint256 amount, bytes holderData) external;
  function operatorBurn(address from, uint256 amount, bytes holderData, bytes operatorData) external;

  event Sent(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes holderData,
    bytes operatorData
  );
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes holderData, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

 
 
 
 
 
 
contract DelegatedTransferOperatorV4 {
  mapping(address => uint256) public usedNonce;
  ERC777Token public tokenContract;

  constructor(address _tokenAddress) public {
    tokenContract = ERC777Token(_tokenAddress);
  }

   
  function transferPreSigned(
    address _to,
    address _delegate,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    bytes _userData,
    bytes32 _sig_r,
    bytes32 _sig_s,
    uint8 _sig_v
  )
    external
  {
    require(
      _delegate == address(0) || _delegate == msg.sender,
      "_delegate should be address(0) or msg.sender"
    );

     
    address _signer = (_sig_v != 27 && _sig_v != 28) ?
      address(0) :
      ecrecover(
        keccak256(abi.encodePacked(
          address(this),
          _to,
          _delegate,
          _value,
          _fee,
          _nonce,
          _userData
        )),
        _sig_v, _sig_r, _sig_s
      );

    require(
      _signer != address(0),
      "_signature is invalid."
    );

    require(
      _nonce > usedNonce[_signer],
      "_nonce must be greater than the last used nonce of the token holder."
    );

    usedNonce[_signer] = _nonce;

    tokenContract.operatorSend(_signer, _to, _value, _userData, "");
    if (_fee > 0) {
      tokenContract.operatorSend(_signer, msg.sender, _fee, _userData, "");
    }
  }

   
  function transferPreSignedHashing(
    address _operator,
    address _to,
    address _delegate,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce,
    bytes _userData
  )
    public
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(
      _operator,
      _to,
      _delegate,
      _value,
      _fee,
      _nonce,
      _userData
    ));
  }

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 0x20))
      s := mload(add(sig, 0x40))
      v := byte(0, mload(add(sig, 0x60)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }
}