 

pragma solidity >=0.4.21 <0.6.0;

contract MultiSigInterface{
  function update_and_check_reach_majority(uint64 id, string memory name, bytes32 hash, address sender) public returns (bool);
  function is_signer(address addr) public view returns(bool);
}

contract MultiSigTools{
  MultiSigInterface public multisig_contract;
  constructor(address _contract) public{
    require(_contract!= address(0x0));
    multisig_contract = MultiSigInterface(_contract);
  }

  modifier only_signer{
    require(multisig_contract.is_signer(msg.sender), "only a signer can call in MultiSigTools");
    _;
  }

  modifier is_majority_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(multisig_contract.update_and_check_reach_majority(id, name, hash, msg.sender)){
      _;
    }
  }

  event TransferMultiSig(address _old, address _new);

  function transfer_multisig(uint64 id, address _contract) public only_signer
  is_majority_sig(id, "transfer_multisig"){
    require(_contract != address(0x0));
    address old = address(multisig_contract);
    multisig_contract = MultiSigInterface(_contract);
    emit TransferMultiSig(old, _contract);
  }
}


contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools{
  TrustListInterface public list;
  constructor(address _list) public {
    require(_list != address(0x0));
    list = TrustListInterface(_list);
  }

  modifier is_trusted(address addr){
    require(list.is_trusted(addr), "not a trusted issuer");
    _;
  }

}


contract TransferableToken{
    function balanceOf(address _owner) public returns (uint256 balance) ;
    function transfer(address _to, uint256 _amount) public returns (bool success) ;
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) ;
}


contract TokenClaimer{

    event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);
     
     
     
     
  function _claimStdTokens(address _token, address payable to) internal {
        if (_token == address(0x0)) {
            to.transfer(address(this).balance);
            return;
        }
        TransferableToken token = TransferableToken(_token);
        uint balance = token.balanceOf(address(this));

        (bool status,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(status, "call failed");
        emit ClaimedTokens(_token, to, balance);
  }
}


contract ERC20TokenBank is MultiSigTools, TokenClaimer, TrustListTools{

  string public token_name;
  address public erc20_token_addr;

  event withdraw_token(address to, uint256 amount);
  event issue_token(address to, uint256 amount);

  constructor(string memory name, address token_contract,
             address _multisig,
             address _tlist) MultiSigTools(_multisig) TrustListTools(_tlist) public{
    token_name = name;
    erc20_token_addr = token_contract;
  }

  function claimStdTokens(uint64 id, address _token, address payable to) public only_signer is_majority_sig(id, "claimStdTokens"){
    _claimStdTokens(_token, to);
  }

  function balance() public returns(uint){
    TransferableToken erc20_token = TransferableToken(erc20_token_addr);
    return erc20_token.balanceOf(address(this));
  }

  function token() public view returns(address, string memory){
    return (erc20_token_addr, token_name);
  }

  function transfer(uint64 id, address to, uint tokens)
    public
    only_signer
    is_majority_sig(id, "transfer")
  returns (bool success){
    require(tokens <= balance(), "not enough tokens");
    (bool status,) = erc20_token_addr.call(abi.encodeWithSignature("transfer(address,uint256)", to, tokens));
    require(status, "call failed");
    emit withdraw_token(to, tokens);
    return true;
  }

  function issue(address _to, uint _amount)
    public
    is_trusted(msg.sender)
    returns (bool success){
      require(_amount <= balance(), "not enough tokens");
      (bool status,) = erc20_token_addr.call(abi.encodeWithSignature("transfer(address,uint256)", _to, _amount));
      require(status, "call failed");
      emit issue_token(_to, _amount);
      return true;
    }
}