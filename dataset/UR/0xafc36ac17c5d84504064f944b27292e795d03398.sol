 

pragma solidity ^0.4.11;

 

contract ERC20 {
  function transfer(address _to, uint _value);
  function balanceOf(address _owner) constant returns (uint balance);
}

contract IOU {
   
  mapping (address => uint256) public iou_purchased;

   
  mapping (address => uint256) public eth_sent;

   
  uint256 public total_iou_available = 40000000000000000000000;

   
  uint256 public total_iou_purchased;

   
  uint256 public total_iou_withdrawn;

   
  uint256 public price_per_eth = 100;

   
  ERC20 public token = ERC20(0xB97048628DB6B661D4C2aA833e95Dbe1A905B280);

   
  address seller = 0x496529c12e229e9787D37E5EFA2E48B651e755B0;

   
  bool public halt_purchases;

  modifier pwner() { if(msg.sender != seller) throw; _; }

   
  function withdrawTokens() pwner {
    token.transfer(seller, token.balanceOf(address(this)) - (total_iou_purchased - total_iou_withdrawn));
  }

   
  function haltPurchases() pwner {
    halt_purchases = true;
  }

  function resumePurchases() pwner {
    halt_purchases = false;
  }

   
  function updateAvailability(uint256 _iou_amount) pwner {
    if(_iou_amount < total_iou_purchased) throw;

    total_iou_available = _iou_amount;
  }

   
  function updatePrice(uint256 _price) pwner {
    price_per_eth = _price;
  }

   
  function paySeller() pwner {
     
    if(token.balanceOf(address(this)) < (total_iou_purchased - total_iou_withdrawn)) throw;

     
    halt_purchases = true;

     
    seller.transfer(this.balance);
  }

  function withdraw() payable {
     
    if(block.number > 4199999 && iou_purchased[msg.sender] > token.balanceOf(address(this))) {
       
       
      uint256 eth_to_refund = eth_sent[msg.sender];

       
      if(eth_to_refund == 0 || iou_purchased[msg.sender] == 0) throw;

       
      total_iou_purchased -= iou_purchased[msg.sender];

       
      eth_sent[msg.sender] = 0;
      iou_purchased[msg.sender] = 0;

      msg.sender.transfer(eth_to_refund);
      return;
    }

     
    if(token.balanceOf(address(this)) == 0 || iou_purchased[msg.sender] > token.balanceOf(address(this))) throw;

    uint256 iou_to_withdraw = iou_purchased[msg.sender];

     
    if(iou_to_withdraw == 0) throw;

     
    iou_purchased[msg.sender] = 0;
    eth_sent[msg.sender] = 0;

    total_iou_withdrawn += iou_to_withdraw;

     
    token.transfer(msg.sender, iou_to_withdraw);
  }

  function purchase() payable {
    if(halt_purchases) throw;
    if(msg.value == 0) throw;

     
    uint256 iou_to_purchase = price_per_eth * msg.value;

     
    if((total_iou_purchased + iou_to_purchase) > total_iou_available) throw;

     
    iou_purchased[msg.sender] += iou_to_purchase;
    eth_sent[msg.sender] += msg.value;

     
    total_iou_purchased += iou_to_purchase;
  }

   
  function () payable {
    if(msg.value == 0) {
      withdraw();
    }
    else {
      purchase();
    }
  }
}