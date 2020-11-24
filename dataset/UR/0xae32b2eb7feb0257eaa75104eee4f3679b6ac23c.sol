 

pragma solidity ^0.4.24;
 
contract EthHashing{

    mapping (address => uint256) public invested;

    mapping (address => uint256) public payments;

    mapping (address => address) public investedRef;

    mapping (address => uint256) public atBlock;

    mapping (address => uint256) public cashBack;

    mapping (address => uint256) public cashRef;

    mapping (address => uint256) public admComiss;

    using SafeMath for uint;
    using ToAddress for *;
    using Zero for *;

    address private adm_addr;  
    uint256 private start_block;
    uint256 private constant dividends = 500;            
    uint256 private constant adm_comission = 10;         
    uint256 private constant ref_bonus = 5;             
    uint256 private constant ref_cashback = 3;           
    uint256 private constant block_of_24h = 5900;        
    uint256 private constant min_invesment = 10 finney;  

     
    uint256 private all_invest_users_count = 0;
    uint256 private all_invest = 0;
    uint256 private all_payments = 0;
    uint256 private all_cash_back_payments = 0;
    uint256 private all_ref_payments = 0;
    uint256 private all_adm_payments = 0;
    uint256 private all_reinvest = 0;
    address private last_invest_addr = 0;
    uint256 private last_invest_amount = 0;
    uint256 private last_invest_block = 0;

    constructor() public {
    adm_addr = msg.sender;
    start_block = block.number;
    }

     
    function() public payable {

        uint256 amount = 0;

         
        if (invested[msg.sender] != 0) {

             
             
             
            amount = invested[msg.sender].mul(dividends).div(10000).mul(block.number.sub(atBlock[msg.sender])).div(block_of_24h);
        }


        if (msg.value == 0) {

             
            if (admComiss[adm_addr] != 0 && msg.sender == adm_addr){
                amount = amount.add(admComiss[adm_addr]);
                admComiss[adm_addr] = 0;
                all_adm_payments += amount;
               }

             
            if (cashRef[msg.sender] != 0){
                amount = amount.add(cashRef[msg.sender]);
                cashRef[msg.sender] = 0;
                all_ref_payments += amount;
            }

             
            if (cashBack[msg.sender] != 0){
                amount = amount.add(cashBack[msg.sender]);
                cashBack[msg.sender] = 0;
                all_cash_back_payments += amount;
               }
           }
        else
           {

             
            require(msg.value >= min_invesment, "msg.value must be >= 0.01 ether (10 finney)");

             
            admComiss[adm_addr] += msg.value.mul(adm_comission).div(100);

            address ref_addr = msg.data.toAddr();

              if (ref_addr.notZero()) {

                  
                 require(msg.sender != ref_addr, "referal must be != msg.sender");

                  
                 cashRef[ref_addr] += msg.value.mul(ref_bonus).div(100);

                  
                 investedRef[msg.sender] = ref_addr;

                  
                 if (invested[msg.sender] == 0)
                     cashBack[msg.sender] += msg.value.mul(ref_cashback).div(100);

                 }
                 else
                 {
                  
                   if (investedRef[msg.sender].notZero())
                      cashRef[investedRef[msg.sender]] += msg.value.mul(ref_bonus).div(100);
                 }


            if (invested[msg.sender] == 0) all_invest_users_count++;

             
            invested[msg.sender] += msg.value;

            atBlock[msg.sender] = block.number;

             
            all_invest += msg.value;
            if (invested[msg.sender] > 0) all_reinvest += msg.value;
            last_invest_addr = msg.sender;
            last_invest_amount = msg.value;
            last_invest_block = block.number;

           }

          
         atBlock[msg.sender] = block.number;

         if (amount != 0)
            {
             
            address sender = msg.sender;

            all_payments += amount;
            payments[sender] += amount;

            sender.transfer(amount);
            }
   }


     
     
    function getFundStatsMap() public view returns (uint256[7]){
    uint256[7] memory stateMap;
    stateMap[0] = all_invest_users_count;
    stateMap[1] = all_invest;
    stateMap[2] = all_payments;
    stateMap[3] = all_cash_back_payments;
    stateMap[4] = all_ref_payments;
    stateMap[5] = all_adm_payments;
    stateMap[6] = all_reinvest;
    return (stateMap);
    }

     
    function getUserStats(address addr) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,address){
    return (invested[addr],cashBack[addr],cashRef[addr],atBlock[addr],block.number,payments[addr],investedRef[addr]);
    }

     
    function getWebStats() public view returns (uint256,uint256,uint256,uint256,address,uint256,uint256){
    return (all_invest_users_count,address(this).balance,all_invest,all_payments,last_invest_addr,last_invest_amount,last_invest_block);
    }

}


library SafeMath {


 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


library ToAddress {
  function toAddr(uint source) internal pure returns(address) {
    return address(source);
  }

  function toAddr(bytes source) internal pure returns(address addr) {
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }
}

library Zero {
  function requireNotZero(uint a) internal pure {
    require(a != 0, "require not zero");
  }

  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }
}