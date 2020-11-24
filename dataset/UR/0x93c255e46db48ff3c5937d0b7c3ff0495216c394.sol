 

pragma solidity ^0.4.11;

contract ERC20 {
  function transfer(address _to, uint _value);
  function balanceOf(address _owner) constant returns (uint balance);
}

contract IOU {
   
  mapping (address => uint256) public iou_purchased;

   
  mapping (address => uint256) public eth_sent;

   
  uint256 public total_iou_available = 20000000000000000000;

   
  uint256 public total_iou_purchased;

   
  ERC20 public token = ERC20(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);

   
  address seller = 0x00203F5b27CB688a402fBDBdd2EaF8542ffF72B6;

   
  function withdrawTokens() {
    if(msg.sender != seller) throw;
    token.transfer(seller, token.balanceOf(address(this)));
  }

  function withdrawEth() {
    if(msg.sender != seller) throw;
    msg.sender.transfer(this.balance);
  }

  function killya() {
    if(msg.sender != seller) throw;
    selfdestruct(seller);
  }

  function withdraw() payable {
     
    if(block.number > 3943365 && iou_purchased[msg.sender] > token.balanceOf(address(this))) {
       
       
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
     
     
     
     

     
    uint256 iou_to_purchase = 8600 * msg.value;  

     
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