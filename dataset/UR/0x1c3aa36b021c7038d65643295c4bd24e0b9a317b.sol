 

pragma solidity ^0.4.11;

 

 
contract AbstractENS {
  function setResolver(bytes32 node, address resolver);
}
contract Resolver {
  function setAddr(bytes32 node, address addr);
}
contract Deed {
  address public previousOwner;
}
contract Registrar {
  function transfer(bytes32 _hash, address newOwner);
  function entries(bytes32 _hash) constant returns (uint, Deed, uint, uint, uint);
}

 
contract SellENS {
  SellENSFactory factory;
  
  function SellENS(){
     
    factory = SellENSFactory(msg.sender);
  }
  
  function () payable {
     
     
     
     
    factory.transfer(msg.value);
    factory.sell_label(msg.sender, msg.value);
  }
}

 
contract SellENSFactory {
   
  struct SellENSInfo {
    string label;
    uint price;
    address owner;
  }
  mapping (address => SellENSInfo) public get_info;
  
   
  address developer = 0x4e6A1c57CdBfd97e8efe831f8f4418b1F2A09e6e;
   
  AbstractENS ens = AbstractENS(0x314159265dD8dbb310642f98f50C066173C1259b);
   
  Registrar registrar = Registrar(0x6090A6e47849629b7245Dfa1Ca21D94cd15878Ef);
   
  Resolver resolver = Resolver(0x1da022710dF5002339274AaDEe8D58218e9D6AB5);
   
  bytes32 root_node = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
  
   
  event SellENSCreated(SellENS sell_ens);
  event LabelSold(SellENS sell_ens);
  
   
  function createSellENS(string label, uint price) {
    SellENS sell_ens = new SellENS();
     
    get_info[sell_ens] = SellENSInfo(label, price, msg.sender);
    SellENSCreated(sell_ens);
  }
  
   
  function sell_label(address buyer, uint amount_paid){
    SellENS sell_ens = SellENS(msg.sender);
     
    if (get_info[sell_ens].owner == 0x0) throw;
    
    string label = get_info[sell_ens].label;
    uint price = get_info[sell_ens].price;
    address owner = get_info[sell_ens].owner;
    
     
    bytes32 label_hash = sha3(label);
     
    Deed deed;
    (,deed,,,) = registrar.entries(label_hash);
     
    if (deed.previousOwner() != owner) throw;
     
    bytes32 node = sha3(root_node, label_hash);
     
    ens.setResolver(node, resolver);
     
    resolver.setAddr(node, buyer);
     
    registrar.transfer(label_hash, buyer);

     
    uint fee = price / 20;
     
    if (buyer == owner) {
      price = 0;
      fee = 0;
    }
     
    developer.transfer(fee);
     
    owner.transfer(price - fee);
     
    if (amount_paid > price) {
      buyer.transfer(amount_paid - price);
    }
    LabelSold(sell_ens);
  }
  
   
  function () payable {}
}