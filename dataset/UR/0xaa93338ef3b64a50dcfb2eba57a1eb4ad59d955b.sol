 

pragma solidity ^0.4.6;

 
 
 
 
 
 
 
contract PPBC_Ether_Claim {
     
     address ppbc;
     
     mapping (bytes32 => uint256) valid_voucher_code;  
     mapping (bytes32 => bool) redeemed;   
     mapping (bytes32 => address) who_claimed;  
     mapping (uint256 => bytes32) claimers;  
     uint256 public num_claimed;             
     uint256 public total_claim_codes;
     bool public deposits_refunded;

      
     function PPBC_Ether_Claim(){
        ppbc = msg.sender;
        deposits_refunded = false;
        num_claimed = 0;
        valid_voucher_code[0x99fc71fa477d1d3e6b6c3ed2631188e045b7f575eac394e50d0d9f182d3b0145] = 110.12 ether; total_claim_codes++;
        valid_voucher_code[0x8b4f72e27b2a84a30fe20b0ee5647e3ca5156e1cb0d980c35c657aa859b03183] = 53.2535 ether; total_claim_codes++;
        valid_voucher_code[0xe7ac3e31f32c5e232eb08a8f978c7e4c4845c44eb9fa36e89b91fc15eedf8ffb] = 151 ether; total_claim_codes++;
        valid_voucher_code[0xc18494ff224d767c15c62993a1c28e5a1dc17d7c41abab515d4fcce2bd6f629d] = 63.22342 ether; total_claim_codes++;
        valid_voucher_code[0x5cdb60c9e999a510d191cf427c9995d6ad3120a6b44afcb922149d275afc8ec4] = 101 ether; total_claim_codes++;
        valid_voucher_code[0x5fb7aed108f910cc73b3e10ceb8c73f90f8d6eff61cda5f43d47f7bec9070af4] = 16.3 ether; total_claim_codes++;
        valid_voucher_code[0x571a888f66f4d74442733441d62a92284f1c11de57198decf9d4c244fb558f29] = 424 ether; total_claim_codes++;
        valid_voucher_code[0x7123fa994a2990c5231d35cb11901167704ab19617fcbc04b93c45cf88b30e94] = 36.6 ether; total_claim_codes++;
        valid_voucher_code[0xdac0e1457b4cf3e53e9952b1f8f3a68a0f288a7e6192314d5b19579a5266cce0] = 419.1 ether; total_claim_codes++;
        valid_voucher_code[0xf836a280ec6c519f6e95baec2caee1ba4e4d1347f81d4758421272b81c4a36cb] = 86.44 ether; total_claim_codes++;
        valid_voucher_code[0x5470e8b8b149aca84ee799f6fd1a6bf885267a1f7c88c372560b28180e2cf056] = 92 ether; total_claim_codes++;
        valid_voucher_code[0x7f52b6f587c87240d471d6fcda1bb3c10c004771c1572443134fd6756c001c9a] = 124.2 ether; total_claim_codes++;
        valid_voucher_code[0x5d435968b687edc305c3adc29523aba1128bd9acd2c40ae2c9835f2e268522e1] = 95.102 ether; total_claim_codes++;
     }

      
      
     function register_claim(string password) payable {
           
          if (msg.value != 50 ether || valid_voucher_code[sha3(password)] == 0) return;  
          
           
          if (redeemed[sha3(password)] || deposits_refunded ) throw; 
          
           
          num_claimed++;
          redeemed[sha3(password)] = true;
          who_claimed[sha3(password)] = msg.sender;
          valid_voucher_code[sha3(password)] += 50 ether;   
          claimers[num_claimed] = sha3(password);    
     }
     
      
      
      
     function refund_deposits(string password){  
            if (deposits_refunded) throw;  
            if (valid_voucher_code[sha3(password)] == 0) throw; 
            
             
            if (num_claimed >= total_claim_codes || block.number >= 2850000 ){   
                 
                for (uint256 index = 1; index <= num_claimed; index++){
                    bytes32 claimcode = claimers[index];
                    address receiver = who_claimed[claimcode];
                    if (!receiver.send(50 ether)) throw;  
                    valid_voucher_code[claimcode] -= 50 ether;   
                }
                deposits_refunded = true;  
            }
            else throw;
             
     }
     
      
      
     function refund_claims(string password){  
            if (!deposits_refunded) throw;  
            if (valid_voucher_code[sha3(password)] == 0) throw; 
            
            for (uint256 index = 1; index <= num_claimed; index++){
                bytes32 claimcode = claimers[index];
                address receiver = who_claimed[claimcode];
                uint256 refund_amount = valid_voucher_code[claimcode];
                
                 
                
                if (this.balance >= refund_amount){
                    if (!receiver.send(refund_amount)) throw;  
                    valid_voucher_code[claimcode] = 0;   
                }
                
            }
     }


      
     
     function end_redeem_period(){ 
            if (block.number >= 2900000 || num_claimed == 0)  
               selfdestruct(ppbc);
     }
    
     function check_redeemed(string password) returns (bool){
         if (valid_voucher_code[sha3(password)] == 0) 
              return true;  
         return redeemed[sha3(password)];
     }
    
     function () payable {}  
}