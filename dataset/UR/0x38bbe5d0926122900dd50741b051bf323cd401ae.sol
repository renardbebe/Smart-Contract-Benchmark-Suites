 

pragma solidity ^0.4.11;

 
contract DaoCasinoToken {
  uint256 public CAP;
  uint256 public totalEthers;
  function proxyPayment(address participant) payable;
  function transfer(address _to, uint _amount) returns (bool success);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract BETSale {
   
  mapping (address => uint256) public bet_purchased;

   
  mapping (address => uint256) public eth_sent;

   
  uint256 public total_bet_available;

   
  uint256 public total_bet_purchased;

   
  uint256 public total_bet_withdrawn;

   
  uint256 public price_per_eth = 900;

   
  DaoCasinoToken public token = DaoCasinoToken(0x725803315519de78D232265A8f1040f054e70B98);

   
  address seller = 0xB00Ae1e677B27Eee9955d632FF07a8590210B366;

   
  bool public halt_purchases;

   
  function withdrawTokens() {
    if(msg.sender != seller) throw;
    if(total_bet_withdrawn != total_bet_purchased) throw;

     
    total_bet_available = 0;
    total_bet_purchased = 0;
    total_bet_withdrawn = 0;

    token.transfer(seller, token.balanceOf(address(this)));
  }

   
  function withdrawETH() {
    if(msg.sender != seller) throw;
    msg.sender.transfer(this.balance);
  }

   
  function buyTokens() payable {
    if(msg.sender != seller) throw;
    if(token.totalEthers() < token.CAP()) {
      token.proxyPayment.value(this.balance)(address(this));
    }
  }

   
  function updateAvailability(uint256 _bet_amount) {
    if(msg.sender != seller) throw;
    total_bet_available += _bet_amount;
  }

   
  function updatePrice(uint256 _price) {
    if(msg.sender != seller) throw;
    price_per_eth = _price;
  }

   
  function haltPurchases() {
    if(msg.sender != seller) throw;
    halt_purchases = true;
  }

  function resumePurchases() {
    if(msg.sender != seller) throw;
    halt_purchases = false;
  }

  function withdraw() {
     
    if(token.balanceOf(address(this)) == 0 || bet_purchased[msg.sender] == 0) throw;

    uint256 bet_to_withdraw = bet_purchased[msg.sender];

     
    bet_purchased[msg.sender] = 0;

    total_bet_withdrawn += bet_to_withdraw;

     
    if(!token.transfer(msg.sender, bet_to_withdraw)) throw;
  }

  function purchase() payable {
    if(halt_purchases) throw;

     
    uint256 bet_to_purchase = price_per_eth * msg.value;

     
    if((total_bet_purchased + bet_to_purchase) > total_bet_available) throw;

     
    bet_purchased[msg.sender] += bet_to_purchase;
    eth_sent[msg.sender] += msg.value;

     
    total_bet_purchased += bet_to_purchase;

     
    seller.transfer(msg.value);
  }

   
  function () payable {
    if(msg.value == 0) {
      withdraw();
    }
    else {
      if(msg.sender == seller) {
        return;
      }
      purchase();
    }
  }
}