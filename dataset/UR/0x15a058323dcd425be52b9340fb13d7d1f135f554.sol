 

pragma solidity ^0.4.11;

 

contract TeaToken {
     

     

    uint256 public pricePreSale = 1000000 wei;                        

    uint256 public priceStage1 = 2000000 wei;         

    uint256 public priceStage2 = 4000000 wei;         

    uint256 tea_tokens;

    mapping(address => uint256) public balanceOf;                

    bool public crowdsaleOpen = true;                                

    string public name = "TeaToken";                              

    string public symbol = "TEAT";

    uint256 public decimals = 8;

    uint256 durationInMinutes = 10080;               

    uint256 public totalAmountOfTeatokensCreated = 0;

    uint256 public totalAmountOfWeiCollected = 0;

    uint256 public preSaleDeadline = now + durationInMinutes * 1 minutes;          

    uint256 public icoStage1Deadline = now + (durationInMinutes * 2) * 1 minutes;          

    uint256 deadmanSwitchDeadline = now + (durationInMinutes * 4) * 1 minutes;          

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Payout(address indexed to, uint256 value);

     

     

     

    address address1 = 0xa1288081489C16bA450AfE33D1E1dF97D33c85fC; 
    address address2 = 0x2DAAf6754DbE3714C0d46ACe2636eb43671034D6; 
    address address3 = 0x86165fd44C96d4eE1e7038D27301E9804D908f0a; 
    address address4 = 0x18555e00bDAEd991f30e530B47fB1c21F93F0389; 
    address address5 = 0xB64BD3310445562802f18e188Bf571D479105029; 
    address address6 = 0x925F937721E56d06401FC4D191F411382127Df83; 
    address address7 = 0x13688Dd97616f85A363d715509529cFdfe489663; 
    address address8 = 0xC89dB702363E8a100a4b04fDF41c9Dfee572627B; 
    address address9 = 0xB11b98305e4d55610EB18C480477A6984Aa7f7e2; 
    address address10 = 0xb2Ef8eae3ADdB4E66268b49467eeA64F6cD937cf; 
    address address11 = 0x46e8180a477349013434e191E63f2AFD645fd153; 
    address address12 = 0xC7b32902a15c02F956F978E9F5A3e43342266bf2; 
    address address13 = 0xA0b43B97B66a84F3791DE513cC8a35213325C1Ba; 
    address address14 = 0xAEe620D07c16c92A7e8E01C096543048ab591bf9; 
    

    address[] adds = [address1, address2, address3, address4, address5, address6, address7, address8, address9, address10, address11, address12, address13, address14];
    uint numAddresses = adds.length;
    uint sendValue;

     
     
    address controllerAddress1 = 0x86165fd44C96d4eE1e7038D27301E9804D908f0a; 
    address controllerAddress2 = 0xa1288081489C16bA450AfE33D1E1dF97D33c85fC; 
    address controllerAddress3 = 0x18555e00bDAEd991f30e530B47fB1c21F93F0389; 

     



    function () payable {



         
        require(crowdsaleOpen);

        uint256 amount = msg.value;                             
         

        if (now <= preSaleDeadline){
        tea_tokens = (amount / pricePreSale);  
         

        }else if (now <= icoStage1Deadline){
        tea_tokens = (amount / priceStage1);  
         
        }else{
        tea_tokens = (amount / priceStage2);                         
        }

        totalAmountOfWeiCollected += amount;                         
        totalAmountOfTeatokensCreated += (tea_tokens/100000000);     
        balanceOf[msg.sender] += tea_tokens;                         
    }

 

    function safeWithdrawal() {

         
         

        require(controllerAddress1 == msg.sender || controllerAddress2 == msg.sender || controllerAddress3 == msg.sender || now >= deadmanSwitchDeadline);
        require(this.balance > 0);

        uint256 sendValue = this.balance / numAddresses;
        for (uint256 i = 0; i<numAddresses; i++){

                 

                if (i == numAddresses-1){

                Payout(adds[i], this.balance);

                if (adds[i].send(this.balance)){}

                }
                else Payout(adds[i], sendValue);
                if (adds[i].send(sendValue)){}
            }

    }

     



    function endCrowdsale() {
         

        require(controllerAddress1 == msg.sender || controllerAddress2 == msg.sender || controllerAddress3 == msg.sender || now >= deadmanSwitchDeadline);
         
        crowdsaleOpen = false;
    }
     
     
     
     

    function transfer(address _to, uint256 _value) {

        require(balanceOf[msg.sender] >= _value);            

        require(balanceOf[_to] + _value >= balanceOf[_to]);  

        balanceOf[msg.sender] -= _value;                      

        balanceOf[_to] += _value;                             

         
        Transfer(msg.sender, _to, _value);
    }
}