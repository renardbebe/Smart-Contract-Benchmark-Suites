 

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

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public;
    function approve(address spender, uint tokens) public;
    function transferFrom(address from, address to, uint tokens) public;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
contract ERC20Salary is SafeMath, MultiSig{
  struct employee_info{
    uint salary;
    uint period;
    uint total;
    uint claimed;
    uint last_block_num;
    bool exists;
  }

  ERC20Interface public erc20_token;
  string public token_name;
  address[] public employee_accounts;
  mapping (address => employee_info) public employee_infos;


  event ClaimedSalary(address account, address to, uint amount);

  constructor(string memory name, address token_contract, address[] memory s) MultiSig(s) public{
    token_name = name;
    erc20_token = ERC20Interface(token_contract);
  }

  function balance() public view returns(uint){
    return erc20_token.balanceOf(address(this));
  }

  function unclaimed_amount() public returns(uint){
    uint total = 0;
    for(uint i = 0; i < employee_accounts.length; ++i){
      _update_salary(employee_accounts[i]);
      uint t = safeSub(employee_infos[employee_accounts[i]].total, employee_infos[employee_accounts[i]].claimed);
      total = safeAdd(total, t);
    }
    return total;
  }

  function add_employee(uint64 id, address account, uint last_block_num, uint period, uint salary)
    external only_signer
    is_majority_sig(id, "add_employee")
    returns(bool)
    {
      require(account != address(0));
      require(last_block_num >0);
      require(period > 0);
      require(salary > 0);
      if(employee_infos[account].exists) return false;

      employee_infos[account].salary = salary;
      employee_infos[account].period = period;
      employee_infos[account].total = 0;
      employee_infos[account].claimed = 0;
      employee_infos[account].last_block_num = last_block_num;
      employee_infos[account].exists = true;

      employee_accounts.push(account);

      return true;
    }

    function config_employee(uint64 id, address account, uint period, uint salary)
      external only_signer
      is_majority_sig(id, "config_employee")
      returns(bool)
    {
      require(employee_infos[account].exists);
      _update_salary(account);

      employee_infos[account].period = period;
      employee_infos[account].salary = salary;
      return true;
    }

    function _update_salary(address account) private {
      employee_info storage ei = employee_infos[account];
      uint p = safeDiv(safeSub(block.number, ei.last_block_num), ei.period);
      if(p == 0) return ;
      ei.total = safeAdd(ei.total, safeMul(p, ei.salary));
      ei.last_block_num = safeAdd(ei.last_block_num, safeMul(p, ei.period));
    }
    function self_info() public returns(uint salary, uint period, uint total,
                                       uint claimed, uint last_claim_block_num){
      require(employee_infos[msg.sender].exists);
      _update_salary(msg.sender);
      salary = employee_infos[msg.sender].salary;
      period = employee_infos[msg.sender].period;
      total = employee_infos[msg.sender].total;
      claimed = employee_infos[msg.sender].claimed;
      last_claim_block_num = employee_infos[msg.sender].last_block_num;
    }

    function claim_salary(address to, uint amount) external returns(bool){
      require(employee_infos[msg.sender].exists);
      _update_salary(msg.sender);
      employee_info storage ei = employee_infos[msg.sender];
      require(safeSub(ei.total, ei.claimed) >= amount);
      require(amount <= balance());
      ei.claimed  = safeAdd(ei.claimed, amount);
      erc20_token.transfer(to, amount);
      return true;
    }

    function transfer(uint64 id, address to, uint tokens)
      external
      only_signer
      is_majority_sig(id, "transfer")
      returns (bool success){
      erc20_token.transfer(to, tokens);
      return true;
    }

    function token() public view returns(address, string memory){
      return (address(erc20_token), token_name);
    }

    function get_employee_count() public view returns(uint){
      return employee_accounts.length;
    }

    function get_employee_info_with_index(uint index) public view only_signer returns(uint salary, uint period, uint total, uint claimed, uint last_claim_block_num){
      require(index >= 0 && index < employee_accounts.length);
      address account = employee_accounts[index];
      require(employee_infos[account].exists);
      salary = employee_infos[account].salary;
      period = employee_infos[account].period;
      total = employee_infos[account].total;
      claimed = employee_infos[account].claimed;
      last_claim_block_num = employee_infos[account].last_block_num;
    }

    function get_employee_info_with_account(address account) public view only_signer returns(uint salary, uint period, uint total, uint claimed, uint last_claim_block_num){
      require(employee_infos[account].exists);
      salary = employee_infos[account].salary;
      period = employee_infos[account].period;
      total = employee_infos[account].total;
      claimed = employee_infos[account].claimed;
      last_claim_block_num = employee_infos[account].last_block_num;
    }
}