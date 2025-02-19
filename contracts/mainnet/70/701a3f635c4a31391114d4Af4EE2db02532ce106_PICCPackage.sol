pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicensed

import "./DataPlayer.sol";
 
contract PICCPackage is DataPlayer {
    using SafeMath for uint;
   IUniswapV2Router02 public immutable uniswapV2Router;
    constructor()
     {
        _owner = msg.sender; 
        ProjectPartyWallet = 0xB7013b756DFB5fb03A3db14C8376b2ce9CeB6e03; 
        RewardWallet = 0x978C175096A21a8676A0Abf81A1cc735C8da3Ae3; 
        ProtectiveWallet = 0x3eAc4B0124404859eC53C1FBc921578014bE1989; 
        
        USDTRewardWallet = 0x569cA2D7a4eC5b5e113D9faeb3FFb3F5C0144a3B; 
        PICCRewardWallet = 0x30CC3C6892c2101EA5E8979653FCB74938BfC334; 
        _operator = msg.sender; 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _USDTIns.approve(address(0x10ED43C718714eb63d5aA57B78B54704E256024E), 10000000000000000000000000000000000000000000000000000);
        setPackagelimit( 1000000000);
    }


 
// 购买套餐
    function BUYPackage(uint256 PackageType,uint256 PackagePartition ) public{
 
        require(PICC_Limit > 0, "Package sell out");  
        require(PackageType > 0, "Package sell out");  
        require( PackagePrice[PackageType] > 0, "Package sell out");  
        uint256 share =  Packageshare[PackageType];
        require( share < PICC_Limit, "Package sell out");  

  

        uint256 USDTBalance = 0;
 
        if(PackagePartition == 0){
            uint256   Price =  PackagePrice[PackageType].mul(2).div(10);
            USDTBalance =   Price;
            _USDTIns.transferFrom(msg.sender, address(this),USDTBalance);
            require( share <= PI_Limit, "Package sell out");  
            PI_Limit = PI_Limit.sub(share);
            if(PackageCC_Limit[PackageType]>= share){
                PICC_Limit = PICC_Limit.sub(share);
                PackageCC_Limit[PackageType] = PackageCC_Limit[PackageType].sub(share);
            }else{
                PackagePI_Limit[PackageType] = PackagePI_Limit[PackageType].add(share);
            }


 


 
        }else if(PackagePartition == 1)
        {
            uint256   Price =  PackagePrice[PackageType].mul(8).div(10);
             USDTBalance = PackagePrice[PackageType];
            _USDTIns.transferFrom(msg.sender, address(this),Price);
            require( share <= CC_Limit, "Package sell out");  

       


 
  
            CC_Limit = CC_Limit.sub(share);
 

            if(PackagePI_Limit[PackageType]>= share){
                PICC_Limit = PICC_Limit.sub(share);
                PackagePI_Limit[PackageType] = PackagePI_Limit[PackageType].sub(share);

            }else{
                PackageCC_Limit[PackageType] = PackageCC_Limit[PackageType].add(share);
            }








        }else  
        {
            uint256   Price =  PackagePrice[PackageType];
             USDTBalance =   Price;

            _USDTIns.transferFrom(msg.sender, address(this),USDTBalance);
            _USDTIns.transfer(ProjectPartyWallet, USDTBalance.mul(2).div(10));

            PICC_Limit = PICC_Limit.sub(share);
            CC_Limit = CC_Limit.sub(share);
            PI_Limit = PI_Limit.sub(share);
        }

        if(PackagePartition > 0){


        address[] memory path = new address[](2);
        path[0] = address(_USDTIns);
        path[1] = address(_PICCIns);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            USDTBalance.mul(6).div(10),
            0,  
            path,
            address(1),
            block.timestamp
        );





            _USDTIns.transfer(RewardWallet, USDTBalance.mul(15).div(100));
            _USDTIns.transfer(ProtectiveWallet, USDTBalance.mul(5).div(100));
        }else {
            _USDTIns.transfer(ProjectPartyWallet, USDTBalance );

        }
    }

   function activation(uint256 PackageType ,uint256 ID  ) public payable   {
 
        require(PICC_Limit > 0, "Package sell out");  
        require(PackageType > 0, "Package sell out");  
 
        uint256 USDTBalance = 0;
        uint256  allowance  = PlayerPackage[msg.sender][PackageType];
        require(allowance > 0, "allowance is 0");  
  
        USDTBalance =  PackagePrice[PackageType] ;

        uint256   share =  Packageshare[PackageType];

 
        PICC_Limit = PICC_Limit.sub(share);
        CC_Limit = CC_Limit.sub(share);
        PI_Limit = PI_Limit.sub(share);

        _USDTIns.transferFrom(USDTRewardWallet, address(this),USDTBalance);


        address[] memory path = new address[](2);
        path[0] = address(_USDTIns);
        path[1] = address(_PICCIns);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            USDTBalance.mul(6).div(10),
            0,  
            path,
            address(1),
            block.timestamp
        );



        _USDTIns.transfer(ProjectPartyWallet, USDTBalance.mul(2).div(10));
        _USDTIns.transfer(RewardWallet, USDTBalance.mul(15).div(100));
        _USDTIns.transfer(ProtectiveWallet, USDTBalance.mul(5).div(100));

        PlayerPackage[msg.sender][PackageType] = PlayerPackage[msg.sender][PackageType].sub(1);

    }   
 



// 套餐转让
   function circulationPackage(uint256 PackageType ,address targetAddress ) public {
        uint256  allowance  = PlayerPackage[msg.sender][PackageType];
        require(allowance > 0, "allowance is 0");  
        PlayerPackage[msg.sender][PackageType] = PlayerPackage[msg.sender][PackageType].sub(1);
        PlayerPackage[targetAddress][PackageType] = PlayerPackage[msg.sender][PackageType].add(1);
    }   




 

  
// PICC合成
    function PICCsynthesis(uint256 ID,uint256 ID1 )  public{   
    }

// PI，CC卡转让
    function PICCturn(uint256 ID,uint256 Packagetype,address playAddress)  public{  
    }

// PICC激活 
    function PICCactivation(uint256 ID)  public{       
    }

    // PICC提现
    function Withdrawal(uint256  Balance)  public{       
    }

    // PC兑换
    function PCexchange(uint256  ID)  public{       
    }

// USDT奖励
    function USDTReward (uint256 USDTBalance,address playAddress)  public only_operator{
        _USDTIns.transferFrom(USDTRewardWallet, address(playAddress),USDTBalance);     
    }

// PICC奖励
    function PICCReward (uint256 PICCBalance,address playAddress)  public only_operator{
         _PICCIns.transferFrom(PICCRewardWallet, address(playAddress),PICCBalance);
    }
  
   
}