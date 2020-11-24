 

pragma solidity ^0.4.11;

 

 
contract ERC20 {
  function transfer(address _to, uint256 _value) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

 
contract StatusContribution {
  uint256 public maxGasPrice;
  uint256 public startBlock;
  uint256 public totalNormalCollected;
  uint256 public finalizedBlock;
  function proxyPayment(address _th) payable returns (bool);
}

 
contract DynamicCeiling {
  function curves(uint currentIndex) returns (bytes32 hash, 
                                              uint256 limit, 
                                              uint256 slopeFactor, 
                                              uint256 collectMinimum);
  uint256 public currentIndex;
  uint256 public revealedCurves;
}

contract StatusBuyer {
   
  mapping (address => uint256) public deposits;
   
  mapping (address => uint256) public simulated_snt;
   
  uint256 public bounty;
   
  bool public bought_tokens;
  
   
  StatusContribution public sale = StatusContribution(0x55d34b686aa8C04921397c5807DB9ECEdba00a4c);
   
  DynamicCeiling public dynamic = DynamicCeiling(0xc636e73Ff29fAEbCABA9E0C3f6833EaD179FFd5c);
   
  ERC20 public token = ERC20(0x744d70FDBE2Ba4CF95131626614a1763DF805B9E);
   
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
  
   
  function withdraw() {
     
    uint256 user_deposit = deposits[msg.sender];
     
    deposits[msg.sender] = 0;
     
    uint256 contract_eth_balance = this.balance - bounty;
     
    uint256 contract_snt_balance = token.balanceOf(address(this));
     
     
    uint256 contract_value = (contract_eth_balance * 10000) + contract_snt_balance;
     
    uint256 eth_amount = (user_deposit * contract_eth_balance * 10000) / contract_value;
     
    uint256 snt_amount = 10000 * ((user_deposit * contract_snt_balance) / contract_value);
     
    uint256 fee = 0;
     
    if (simulated_snt[msg.sender] < snt_amount) {
      fee = (snt_amount - simulated_snt[msg.sender]) / 100;
    }
     
    if(!token.transfer(msg.sender, snt_amount - fee)) throw;
    if(!token.transfer(developer, fee)) throw;
    msg.sender.transfer(eth_amount);
  }
  
   
  function add_to_bounty() payable {
     
    if (bought_tokens) throw;
     
    bounty += msg.value;
  }
  
   
  function simulate_ico() {
     
    if (tx.gasprice > sale.maxGasPrice()) throw;
     
    if (block.number < sale.startBlock()) throw;
    if (dynamic.revealedCurves() == 0) throw;
     
    uint256 limit;
    uint256 slopeFactor;
    (,limit,slopeFactor,) = dynamic.curves(dynamic.currentIndex());
     
    uint256 totalNormalCollected = sale.totalNormalCollected();
     
    if (limit <= totalNormalCollected) throw;
     
    simulated_snt[msg.sender] += ((limit - totalNormalCollected) / slopeFactor);
  }
  
   
  function buy() {
     
    if (bought_tokens) return;
     
    bought_tokens = true;
     
     
     
    sale.proxyPayment.value(this.balance - bounty)(address(this));
     
    msg.sender.transfer(bounty);
  }
  
   
  function default_helper() payable {
     
    if (!bought_tokens) {
       
      deposits[msg.sender] += msg.value;
       
      if (deposits[msg.sender] > 30 ether) throw;
    }
    else {
       
      if (msg.value != 0) throw;
       
      if (sale.finalizedBlock() == 0) {
        simulate_ico();
      }
      else {
         
        withdraw();
      }
    }
  }
  
   
  function () payable {
     
    if (msg.sender == address(sale)) return;
     
    default_helper();
  }
}