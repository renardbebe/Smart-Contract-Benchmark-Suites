 

 
pragma solidity >=0.4.21 <0.6.0;

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


pragma solidity >=0.4.21 <0.6.0;

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


pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


pragma solidity >=0.4.21 <0.6.0;





contract GTTokenInterface is TransferableToken{
    function destroyTokens(address _owner, uint _amount) public returns (bool);
    function generateTokens(address _owner, uint _amount) public returns (bool);
}


contract FundAndDistribute is TokenClaimer, MultiSigTools, TrustListTools{
  using SafeMath for uint;

  string public name;
  string public desc;
  address public token_contract;
  uint public tokens_per_k_gt;
  uint public exchange_ratio;  
  GTTokenInterface public gt_token;
  bool public paused;

  event Fund(address addr, address token, uint cost_amount, uint remain, uint got_amount);
  event Exchange(address addr, address token, uint cost_amout, uint remain, uint got_amount);

  constructor(address _gt_token,
              string memory _name,
              string memory _desc,
              address _token_contract,
              address _multisig,
              address _tlist)  public MultiSigTools(_multisig) TrustListTools(_tlist){
    gt_token = GTTokenInterface(_gt_token);
    name = _name;
    desc = _desc;
    token_contract = _token_contract;
    tokens_per_k_gt = 1000;
    exchange_ratio = 20;  
    paused = false;
  }

  function balance() public returns(uint){
      TransferableToken token = TransferableToken(address(gt_token));
      return token.balanceOf(address(this));
  }
  function transfer(uint64 id, address to, uint amount)
    public
    only_signer
    is_majority_sig(id, "transfer")
  returns (bool success){
      TransferableToken token = TransferableToken(address(gt_token));
      token.transfer(to, amount);
      return true;
  }

    function claimStdTokens(uint64 id, address _token, address payable to) public only_signer is_majority_sig(id, "claimStdTokens"){
      _claimStdTokens(_token, to);
    }
  modifier when_paused(){
    require(paused == true, "require paused");
    _;
  }
  modifier when_not_paused(){
    require(paused == false, "require not paused");
    _;
  }

    function pause(uint64 id) public only_signer is_majority_sig(id, "pause"){
      paused = true;
    }
    function unpause(uint64 id) public only_signer is_majority_sig(id, "unpause"){
      paused = false;
    }

    function set_param(uint64 id, uint _tokens_per_k_gt, uint _exchange_ratio) public only_signer is_majority_sig(id, "set_param"){
      require(_tokens_per_k_gt > 0);
      require(_exchange_ratio > 0);
      tokens_per_k_gt = _tokens_per_k_gt;
      exchange_ratio = _exchange_ratio;
    }

     
    function _fund(uint _amount) internal returns(uint remain){
      uint v = SafeMath.safeDiv(_amount, tokens_per_k_gt);
      uint cost = SafeMath.safeMul(v, tokens_per_k_gt);
      remain = SafeMath.safeSub(_amount, cost);
      v = SafeMath.safeMul(v, 1000);
      gt_token.generateTokens(msg.sender, v);
      gt_token.generateTokens(address(this), v);
      emit Fund(msg.sender, token_contract, cost, remain, v);
    }

     
    function _exchange(uint _amount) internal returns(uint remain_token){
      require(_amount > 0, "fund should be > 0");
      GTTokenInterface token = GTTokenInterface(address(gt_token));
      uint old_balance = token.balanceOf(msg.sender);
      require(old_balance >= _amount, "not enough amout");

      uint k_gts = SafeMath.safeDiv(_amount, 1000);
      uint cost = SafeMath.safeMul(k_gts, 1000);
      uint r = SafeMath.safeSub(_amount, cost);
      uint burn = SafeMath.safeSub(_amount, r);
      if(burn > 0){
        token.destroyTokens(msg.sender, burn);
      }
      remain_token = SafeMath.safeMul(k_gts, tokens_per_k_gt);
      remain_token = SafeMath.safeDiv(SafeMath.safeMul(remain_token, 10), exchange_ratio);
      emit Exchange(msg.sender, token_contract,cost, r, remain_token);
    }

  function fund(uint amount) public when_not_paused is_trusted(msg.sender) returns (bool){
    require(amount > 0, "fund should be > 0");
    TransferableToken token = TransferableToken(token_contract);
    uint old_balance = token.balanceOf(address(this));
    (bool ret, ) = token_contract.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
    require(ret, "FundAndDistribute:fund, transferFrom return false");
    uint new_balance = token.balanceOf(address(this));
    require(new_balance == old_balance + amount, "StdFundAndDistribute:fund, invalid transfer");
    uint remain = _fund(amount);
    if(remain > 0){
      token.transfer(msg.sender, remain);
    }
    return true;
  }

  function exchange(uint amount) public when_not_paused returns(bool){
    uint ret_token_amount = _exchange(amount);
    if(ret_token_amount > 0){
      (bool ret, ) = token_contract.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, ret_token_amount));
      require(ret, "FundAndDistribute:fund, transferFrom return false");
    }
    return true;
  }
}