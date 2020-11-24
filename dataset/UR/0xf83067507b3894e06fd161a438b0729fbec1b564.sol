 

pragma solidity >=0.4.21 <0.6.0;

contract MultiSig{

  struct invoke_status{
    uint propose_height;
    bytes32 invoke_hash;
    string func_name;
    uint64 invoke_id;
    bool called;
    address[] invoke_signers;
    bool processing;
    bool exists;
  }

  uint public signer_number;
  address[] public signers;
  address public owner;
  mapping (bytes32 => invoke_status) public invokes;
  mapping (bytes32 => uint64) public used_invoke_ids;
  mapping(address => uint) public signer_join_height;

  event signers_reformed(address[] old_signers, address[] new_signers);
  event valid_function_sign(string name, uint64 id, uint64 current_signed_number, uint propose_height);
  event function_called(string name, uint64 id, uint propose_height);

  modifier enough_signers(address[] memory s){
    require(s.length >=3, "the number of signers must be >=3");
    _;
  }
  constructor(address[] memory s) public enough_signers(s){
    signers = s;
    signer_number = s.length;
    owner = msg.sender;
    for(uint i = 0; i < s.length; i++){
      signer_join_height[s[i]] = block.number;
    }
  }

  modifier only_signer{
    require(array_exist(signers, msg.sender), "only a signer can call this");
    _;
  }

  function get_majority_number() private view returns(uint){
    return signer_number/2 + 1;
  }

  function array_exist (address[] memory accounts, address p) private pure returns (bool){
    for (uint i = 0; i< accounts.length;i++){
      if (accounts[i]==p){
        return true;
      }
    }
    return false;
  }

  function is_all_minus_sig(uint number, uint64 id, string memory name, bytes32 hash, address sender) internal only_signer returns (bool){
    bytes32 b = keccak256(abi.encodePacked(name));
    require(id <= used_invoke_ids[b] + 1, "you're using a too big id.");

    if(id > used_invoke_ids[b]){
      used_invoke_ids[b] = id;
    }

    if(!invokes[hash].exists){
      invokes[hash].propose_height = block.number;
      invokes[hash].invoke_hash = hash;
      invokes[hash].func_name= name;
      invokes[hash].invoke_id= id;
      invokes[hash].called= false;
      invokes[hash].invoke_signers.push(sender);
      invokes[hash].processing= false;
      invokes[hash].exists= true;
      emit valid_function_sign(name, id, 1, block.number);
      return false;
    }

    invoke_status storage invoke = invokes[hash];
    require(!array_exist(invoke.invoke_signers, sender), "you already called this method");

    uint valid_invoke_num = 0;
    uint join_height = signer_join_height[msg.sender];
    for(uint i = 0; i < invoke.invoke_signers.length; i++){
      require(join_height < invoke.propose_height, "this proposal is already exist before you become a signer");
      if(array_exist(signers, invoke.invoke_signers[i])){
        valid_invoke_num ++;
      }
    }
    invoke.invoke_signers.push(msg.sender);
    valid_invoke_num ++;
    emit valid_function_sign(name, id, uint64(valid_invoke_num), invoke.propose_height);
    if(invoke.called) return false;
    if(valid_invoke_num < signer_number-number) return false;
    invoke.processing = true;
    return true;
  }

  modifier is_majority_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(!is_all_minus_sig(get_majority_number()-1, id, name, hash, msg.sender))
      return ;
    set_called(hash);
    _;
  }

  modifier is_all_sig(uint64 id, string memory name) {
    bytes32 hash = keccak256(abi.encodePacked(msg.sig, msg.data));
    if(!is_all_minus_sig(0, id, name, hash, msg.sender)) return ;
    set_called(hash);
    _;
  }

  function set_called(bytes32 hash) internal only_signer{
    invoke_status storage invoke = invokes[hash];
    require(invoke.exists, "no such function");
    require(!invoke.called, "already called");
    require(invoke.processing, "cannot call this separately");
    invoke.called = true;
    invoke.processing = false;
    emit function_called(invoke.func_name, invoke.invoke_id, invoke.propose_height);
  }

  function reform_signers(uint64 id, address[] calldata s)
    external
    only_signer
    enough_signers(s)
    is_majority_sig(id, "reform_signers"){
    address[] memory old_signers = signers;
    for(uint i = 0; i < s.length; i++){
      if(array_exist(old_signers, s[i])){
      }else{
        signer_join_height[s[i]] = block.number;
      }
    }
    for(uint i = 0; i < old_signers.length; i++){
      if(array_exist(s, old_signers[i])){
      }else{
        signer_join_height[old_signers[i]] = 0;
      }
    }
    signer_number = s.length;
    signers = s;
    emit signers_reformed(old_signers, signers);
  }

  function get_unused_invoke_id(string memory name) public view returns(uint64){
    return used_invoke_ids[keccak256(abi.encodePacked(name))] + 1;
  }
  function get_signers() public view returns(address[] memory){
    return signers;
  }
}

contract SafeMath {
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

contract ChatTokenInterface{
  function issue(address account, uint num) public;
}

contract ChatTokenIssue is SafeMath, MultiSig{

  uint public ratio;
  uint public price_x_base;
  uint public last_def_price_block_num;
  uint public adjust_price_period;
  uint public adjust_price_unit;

  bool private paused;

  ChatTokenInterface chattoken;

  event Exchange(address, uint base, uint eth_amount, uint cat_amount);
  event SetParam(uint ratio, uint p, uint u);
  event Paused();
  event Unpaused();
  event TransferETH(address account, uint amount);

  constructor(address contract_address, address[] memory s) MultiSig(s) public {
    chattoken = ChatTokenInterface(contract_address);
    last_def_price_block_num = block.number;
    paused = false;
  }

  modifier when_paused(){
    require(paused == true, "require paused");
    _;
  }

  modifier when_not_paused(){
    require(paused == false, "require not paused");
    _;
  }

  function pause(uint64 id) public when_not_paused only_signer is_majority_sig(id, "pause"){
    paused = true;
    emit Paused();
  }
  function unpause(uint64 id) public when_paused only_signer is_majority_sig(id, "unpause"){
    paused = false;
    emit Unpaused();
  }

  function issue_for_ar(uint64 id, address[] memory accounts, uint[] memory nums)
    public
    only_signer
    is_majority_sig(id, "issue_for_ar"){
      require(accounts.length == nums.length);
      require(accounts.length != 0);
      for(uint i = 0; i < accounts.length; i++){
        chattoken.issue(accounts[i], nums[i]);
      }
  }

  function airdrop(uint64 id, address[] memory accounts)
    public
    only_signer
    is_majority_sig(id, "airdrop"){
      require(accounts.length != 0);
      for(uint i = 0; i < accounts.length; i++){
        chattoken.issue(accounts[i], 1000);
      }
  }

  function exchange() public payable
    when_not_paused
    returns(bool){
    require(msg.value > 0);
    uint price = cur_price();
    if(price >= msg.value){
      msg.sender.transfer(msg.value);
      return false;
    }

    uint v = msg.value;
    uint min = 1;
    uint max = safeDiv(v, safeMul(price_x_base + min, ratio));

    while(min < max){
      uint t = safeDiv(safeAdd(min, max), 2);
      uint amount = _sum(price_x_base, t);
      uint s = safeMul(ratio, amount);

      if(s > v){
        max = t - 1;
      }else if(s < v){
        min = t + 1;
      }
      else if(s == v){
        exchange_with_value_price(t, 0);
        return true;
      }
    }
    uint amount = _sum(price_x_base, max);
    uint s = safeMul(ratio, amount);
    if(s > v){
      amount = _sum(price_x_base, max - 1);
      s = safeMul(ratio, amount);
      max = max - 1;
    }
    uint r = safeSub(v, s);
    exchange_with_value_price(max, r);
    return true;
  }

  function _sum(uint x0, uint t) private pure returns(uint){
    return safeAdd(safeMul(t, x0), safeDiv(safeMul(t, t+1), 2));
  }

  function exchange_with_value_price(uint amount, uint r) private{
    if(r != 0){
      msg.sender.transfer(r);
    }

    uint base = price_x_base;
    price_x_base += amount;
    last_def_price_block_num = block.number;
    chattoken.issue(msg.sender, amount);
    emit Exchange(msg.sender, base, safeSub(msg.value,  r), amount);
  }

  function cur_price() public returns(uint){
    uint period = safeDiv(safeSub(block.number, last_def_price_block_num), adjust_price_period);
    uint minus_base = safeMul(period, adjust_price_unit);
    if(minus_base >= price_x_base){
      price_x_base = 0;
    }else{
      price_x_base = safeSub(price_x_base, minus_base);
    }
    return _price(price_x_base);
  }

  function _price(uint p) internal view returns(uint){
    return safeMul(p + 1, ratio);
  }

  function set_param(uint64 id, uint r, uint p, uint u)
    external
    only_signer
    is_majority_sig(id, "set_param"){
      ratio = r;
      adjust_price_period = p;
      adjust_price_unit = u;
      emit SetParam(r, p, u);
  }

  function balance() public view returns (uint){
    return address(this).balance;
  }

  function transfer(uint64 id, address payable account, uint amount) public only_signer is_majority_sig(id, "transfer"){
    require(amount <= address(this).balance);
    account.transfer(amount);
    emit TransferETH(account, amount);
  }

}