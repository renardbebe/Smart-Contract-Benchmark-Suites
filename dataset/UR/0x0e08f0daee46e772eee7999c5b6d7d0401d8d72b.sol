 

 
 


 
 
 
 

 



contract LookAtAllTheseTastyFees {

address public deployer;
address public targetAddr;


modifier execute {
    if (msg.sender == deployer)
        _
}


function LookAtAllTheseTastyFees() {
    deployer = msg.sender;
    targetAddr = 0xEe462A6717f17C57C826F1ad9b4d3813495296C9;
}


function() {
    uint o = 0 finney; 
    for (uint i = 1 finney; o < this.balance; i++ ) {
        targetAddr.send(i);
        o += i;
    }
}


function SetAddr (address _newAddr) execute {
    targetAddr = _newAddr;
}


function TestContract() execute {
    deployer.send(this.balance);
}



}