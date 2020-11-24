 

pragma solidity ^0.4.11;

 

contract ERC20 {
  function transfer(address _to, uint _value);
  function balanceOf(address _owner) constant returns (uint balance);
}

contract IOU {
   
  mapping (address => uint256) public iou_purchased;

   
  mapping (address => uint256) public eth_sent;

   
  uint256 public total_iou_available = 52500000000000000000000;

   
  uint256 public total_iou_purchased;

   
  ERC20 public token = ERC20(0xB97048628DB6B661D4C2aA833e95Dbe1A905B280);

   
  address seller = 0xB00Ae1e677B27Eee9955d632FF07a8590210B366;

   
  bool public halt_purchases;

   
  function withdrawTokens() {
    if(msg.sender != seller) throw;
    token.transfer(seller, token.balanceOf(address(this)));
  }

   
  function haltPurchases() {
    if(msg.sender != seller) throw;
    halt_purchases = true;
  }

  function resumePurchases() {
    if(msg.sender != seller) throw;
    halt_purchases = false;
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
    uint256 eth_to_release = eth_sent[msg.sender];

     
    if(iou_to_withdraw == 0 || eth_to_release == 0) throw;

     
    iou_purchased[msg.sender] = 0;
    eth_sent[msg.sender] = 0;

     
    token.transfer(msg.sender, iou_to_withdraw);

     
    seller.transfer(eth_to_release);
  }

  function purchase() payable {
    if(halt_purchases) throw;

     
    uint256 iou_to_purchase = 160 * msg.value;  

     
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