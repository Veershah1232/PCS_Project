
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	23813103          	ld	sp,568(sp) # 8000a238 <_GLOBAL_OFFSET_TABLE_+0x8>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	stimecmp,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb077>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dbc78793          	addi	a5,a5,-580 # 80000e3c <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
// user write() system calls to the console go here.
// uses sleep() and UART interrupts.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7119                	addi	sp,sp,-128
    800000d2:	fc86                	sd	ra,120(sp)
    800000d4:	f8a2                	sd	s0,112(sp)
    800000d6:	f4a6                	sd	s1,104(sp)
    800000d8:	0100                	addi	s0,sp,128
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000da:	06c05a63          	blez	a2,8000014e <consolewrite+0x7e>
    800000de:	f0ca                	sd	s2,96(sp)
    800000e0:	ecce                	sd	s3,88(sp)
    800000e2:	e8d2                	sd	s4,80(sp)
    800000e4:	e4d6                	sd	s5,72(sp)
    800000e6:	e0da                	sd	s6,64(sp)
    800000e8:	fc5e                	sd	s7,56(sp)
    800000ea:	f862                	sd	s8,48(sp)
    800000ec:	f466                	sd	s9,40(sp)
    800000ee:	8aaa                	mv	s5,a0
    800000f0:	8b2e                	mv	s6,a1
    800000f2:	8a32                	mv	s4,a2
  int i = 0;
    800000f4:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f6:	02000c13          	li	s8,32
    800000fa:	02000c93          	li	s9,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fe:	5bfd                	li	s7,-1
    80000100:	a035                	j	8000012c <consolewrite+0x5c>
    if(nn > n - i)
    80000102:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000106:	86ce                	mv	a3,s3
    80000108:	01648633          	add	a2,s1,s6
    8000010c:	85d6                	mv	a1,s5
    8000010e:	f8040513          	addi	a0,s0,-128
    80000112:	1ce020ef          	jal	800022e0 <either_copyin>
    80000116:	03750e63          	beq	a0,s7,80000152 <consolewrite+0x82>
      break;
    uartwrite(buf, nn);
    8000011a:	85ce                	mv	a1,s3
    8000011c:	f8040513          	addi	a0,s0,-128
    80000120:	778000ef          	jal	80000898 <uartwrite>
    i += nn;
    80000124:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000128:	0144da63          	bge	s1,s4,8000013c <consolewrite+0x6c>
    if(nn > n - i)
    8000012c:	409a093b          	subw	s2,s4,s1
    80000130:	0009079b          	sext.w	a5,s2
    80000134:	fcfc57e3          	bge	s8,a5,80000102 <consolewrite+0x32>
    80000138:	8966                	mv	s2,s9
    8000013a:	b7e1                	j	80000102 <consolewrite+0x32>
    8000013c:	7906                	ld	s2,96(sp)
    8000013e:	69e6                	ld	s3,88(sp)
    80000140:	6a46                	ld	s4,80(sp)
    80000142:	6aa6                	ld	s5,72(sp)
    80000144:	6b06                	ld	s6,64(sp)
    80000146:	7be2                	ld	s7,56(sp)
    80000148:	7c42                	ld	s8,48(sp)
    8000014a:	7ca2                	ld	s9,40(sp)
    8000014c:	a819                	j	80000162 <consolewrite+0x92>
  int i = 0;
    8000014e:	4481                	li	s1,0
    80000150:	a809                	j	80000162 <consolewrite+0x92>
    80000152:	7906                	ld	s2,96(sp)
    80000154:	69e6                	ld	s3,88(sp)
    80000156:	6a46                	ld	s4,80(sp)
    80000158:	6aa6                	ld	s5,72(sp)
    8000015a:	6b06                	ld	s6,64(sp)
    8000015c:	7be2                	ld	s7,56(sp)
    8000015e:	7c42                	ld	s8,48(sp)
    80000160:	7ca2                	ld	s9,40(sp)
  }

  return i;
}
    80000162:	8526                	mv	a0,s1
    80000164:	70e6                	ld	ra,120(sp)
    80000166:	7446                	ld	s0,112(sp)
    80000168:	74a6                	ld	s1,104(sp)
    8000016a:	6109                	addi	sp,sp,128
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	0f450513          	addi	a0,a0,244 # 80012280 <cons>
    80000194:	23b000ef          	jal	80000bce <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00012497          	auipc	s1,0x12
    8000019c:	0e848493          	addi	s1,s1,232 # 80012280 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00012917          	auipc	s2,0x12
    800001a4:	17890913          	addi	s2,s2,376 # 80012318 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	716010ef          	jal	800018ce <myproc>
    800001bc:	7b7010ef          	jal	80002172 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	575010ef          	jal	80001f3a <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	00012717          	auipc	a4,0x12
    800001dc:	0a870713          	addi	a4,a4,168 # 80012280 <cons>
    800001e0:	0017869b          	addiw	a3,a5,1
    800001e4:	08d72c23          	sw	a3,152(a4)
    800001e8:	07f7f693          	andi	a3,a5,127
    800001ec:	9736                	add	a4,a4,a3
    800001ee:	01874703          	lbu	a4,24(a4)
    800001f2:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001f6:	4691                	li	a3,4
    800001f8:	04db8663          	beq	s7,a3,80000244 <consoleread+0xd6>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    800001fc:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000200:	4685                	li	a3,1
    80000202:	faf40613          	addi	a2,s0,-81
    80000206:	85d2                	mv	a1,s4
    80000208:	8556                	mv	a0,s5
    8000020a:	08c020ef          	jal	80002296 <either_copyout>
    8000020e:	57fd                	li	a5,-1
    80000210:	04f50863          	beq	a0,a5,80000260 <consoleread+0xf2>
      break;

    dst++;
    80000214:	0a05                	addi	s4,s4,1
    --n;
    80000216:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000218:	47a9                	li	a5,10
    8000021a:	04fb8d63          	beq	s7,a5,80000274 <consoleread+0x106>
    8000021e:	6be2                	ld	s7,24(sp)
    80000220:	b761                	j	800001a8 <consoleread+0x3a>
        release(&cons.lock);
    80000222:	00012517          	auipc	a0,0x12
    80000226:	05e50513          	addi	a0,a0,94 # 80012280 <cons>
    8000022a:	23d000ef          	jal	80000c66 <release>
        return -1;
    8000022e:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000230:	60e6                	ld	ra,88(sp)
    80000232:	6446                	ld	s0,80(sp)
    80000234:	64a6                	ld	s1,72(sp)
    80000236:	6906                	ld	s2,64(sp)
    80000238:	79e2                	ld	s3,56(sp)
    8000023a:	7a42                	ld	s4,48(sp)
    8000023c:	7aa2                	ld	s5,40(sp)
    8000023e:	7b02                	ld	s6,32(sp)
    80000240:	6125                	addi	sp,sp,96
    80000242:	8082                	ret
      if(n < target){
    80000244:	0009871b          	sext.w	a4,s3
    80000248:	01677a63          	bgeu	a4,s6,8000025c <consoleread+0xee>
        cons.r--;
    8000024c:	00012717          	auipc	a4,0x12
    80000250:	0cf72623          	sw	a5,204(a4) # 80012318 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	00012517          	auipc	a0,0x12
    80000266:	01e50513          	addi	a0,a0,30 # 80012280 <cons>
    8000026a:	1fd000ef          	jal	80000c66 <release>
  return target - n;
    8000026e:	413b053b          	subw	a0,s6,s3
    80000272:	bf7d                	j	80000230 <consoleread+0xc2>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	b7f5                	j	80000262 <consoleread+0xf4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50863          	beq	a0,a5,80000294 <consputc+0x1c>
    uartputc_sync(c);
    80000288:	6a4000ef          	jal	8000092c <uartputc_sync>
}
    8000028c:	60a2                	ld	ra,8(sp)
    8000028e:	6402                	ld	s0,0(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000294:	4521                	li	a0,8
    80000296:	696000ef          	jal	8000092c <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	68e000ef          	jal	8000092c <uartputc_sync>
    800002a2:	4521                	li	a0,8
    800002a4:	688000ef          	jal	8000092c <uartputc_sync>
    800002a8:	b7d5                	j	8000028c <consputc+0x14>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	1000                	addi	s0,sp,32
    800002b4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b6:	00012517          	auipc	a0,0x12
    800002ba:	fca50513          	addi	a0,a0,-54 # 80012280 <cons>
    800002be:	111000ef          	jal	80000bce <acquire>

  switch(c){
    800002c2:	47d5                	li	a5,21
    800002c4:	08f48f63          	beq	s1,a5,80000362 <consoleintr+0xb8>
    800002c8:	0297c563          	blt	a5,s1,800002f2 <consoleintr+0x48>
    800002cc:	47a1                	li	a5,8
    800002ce:	0ef48463          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    800002d2:	47c1                	li	a5,16
    800002d4:	10f49563          	bne	s1,a5,800003de <consoleintr+0x134>
  case C('P'):  // Print process list.
    procdump();
    800002d8:	052020ef          	jal	8000232a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	00012517          	auipc	a0,0x12
    800002e0:	fa450513          	addi	a0,a0,-92 # 80012280 <cons>
    800002e4:	183000ef          	jal	80000c66 <release>
}
    800002e8:	60e2                	ld	ra,24(sp)
    800002ea:	6442                	ld	s0,16(sp)
    800002ec:	64a2                	ld	s1,8(sp)
    800002ee:	6105                	addi	sp,sp,32
    800002f0:	8082                	ret
  switch(c){
    800002f2:	07f00793          	li	a5,127
    800002f6:	0cf48063          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fa:	00012717          	auipc	a4,0x12
    800002fe:	f8670713          	addi	a4,a4,-122 # 80012280 <cons>
    80000302:	0a072783          	lw	a5,160(a4)
    80000306:	09872703          	lw	a4,152(a4)
    8000030a:	9f99                	subw	a5,a5,a4
    8000030c:	07f00713          	li	a4,127
    80000310:	fcf766e3          	bltu	a4,a5,800002dc <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000314:	47b5                	li	a5,13
    80000316:	0cf48763          	beq	s1,a5,800003e4 <consoleintr+0x13a>
      consputc(c);
    8000031a:	8526                	mv	a0,s1
    8000031c:	f5dff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000320:	00012797          	auipc	a5,0x12
    80000324:	f6078793          	addi	a5,a5,-160 # 80012280 <cons>
    80000328:	0a07a683          	lw	a3,160(a5)
    8000032c:	0016871b          	addiw	a4,a3,1
    80000330:	0007061b          	sext.w	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48563          	beq	s1,a5,8000040e <consoleintr+0x164>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48263          	beq	s1,a5,8000040e <consoleintr+0x164>
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	fca7a783          	lw	a5,-54(a5) # 80012318 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	00012717          	auipc	a4,0x12
    80000368:	f1c70713          	addi	a4,a4,-228 # 80012280 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	00012497          	auipc	s1,0x12
    80000378:	f0c48493          	addi	s1,s1,-244 # 80012280 <cons>
    while(cons.e != cons.w &&
    8000037c:	4929                	li	s2,10
    8000037e:	02f70863          	beq	a4,a5,800003ae <consoleintr+0x104>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000382:	37fd                	addiw	a5,a5,-1
    80000384:	07f7f713          	andi	a4,a5,127
    80000388:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000038a:	01874703          	lbu	a4,24(a4)
    8000038e:	03270263          	beq	a4,s2,800003b2 <consoleintr+0x108>
      cons.e--;
    80000392:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000396:	10000513          	li	a0,256
    8000039a:	edfff0ef          	jal	80000278 <consputc>
    while(cons.e != cons.w &&
    8000039e:	0a04a783          	lw	a5,160(s1)
    800003a2:	09c4a703          	lw	a4,156(s1)
    800003a6:	fcf71ee3          	bne	a4,a5,80000382 <consoleintr+0xd8>
    800003aa:	6902                	ld	s2,0(sp)
    800003ac:	bf05                	j	800002dc <consoleintr+0x32>
    800003ae:	6902                	ld	s2,0(sp)
    800003b0:	b735                	j	800002dc <consoleintr+0x32>
    800003b2:	6902                	ld	s2,0(sp)
    800003b4:	b725                	j	800002dc <consoleintr+0x32>
    if(cons.e != cons.w){
    800003b6:	00012717          	auipc	a4,0x12
    800003ba:	eca70713          	addi	a4,a4,-310 # 80012280 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	00012717          	auipc	a4,0x12
    800003d0:	f4f72a23          	sw	a5,-172(a4) # 80012320 <cons+0xa0>
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	ea1ff0ef          	jal	80000278 <consputc>
    800003dc:	b701                	j	800002dc <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003de:	ee048fe3          	beqz	s1,800002dc <consoleintr+0x32>
    800003e2:	bf21                	j	800002fa <consoleintr+0x50>
      consputc(c);
    800003e4:	4529                	li	a0,10
    800003e6:	e93ff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003ea:	00012797          	auipc	a5,0x12
    800003ee:	e9678793          	addi	a5,a5,-362 # 80012280 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	00012797          	auipc	a5,0x12
    80000412:	f0c7a723          	sw	a2,-242(a5) # 8001231c <cons+0x9c>
        wakeup(&cons.r);
    80000416:	00012517          	auipc	a0,0x12
    8000041a:	f0250513          	addi	a0,a0,-254 # 80012318 <cons+0x98>
    8000041e:	369010ef          	jal	80001f86 <wakeup>
    80000422:	bd6d                	j	800002dc <consoleintr+0x32>

0000000080000424 <consoleinit>:

void
consoleinit(void)
{
    80000424:	1141                	addi	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000042c:	00007597          	auipc	a1,0x7
    80000430:	bd458593          	addi	a1,a1,-1068 # 80007000 <etext>
    80000434:	00012517          	auipc	a0,0x12
    80000438:	e4c50513          	addi	a0,a0,-436 # 80012280 <cons>
    8000043c:	712000ef          	jal	80000b4e <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00022797          	auipc	a5,0x22
    80000448:	1ac78793          	addi	a5,a5,428 # 800225f0 <devsw>
    8000044c:	00000717          	auipc	a4,0x0
    80000450:	d2270713          	addi	a4,a4,-734 # 8000016e <consoleread>
    80000454:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000456:	00000717          	auipc	a4,0x0
    8000045a:	c7a70713          	addi	a4,a4,-902 # 800000d0 <consolewrite>
    8000045e:	ef98                	sd	a4,24(a5)
}
    80000460:	60a2                	ld	ra,8(sp)
    80000462:	6402                	ld	s0,0(sp)
    80000464:	0141                	addi	sp,sp,16
    80000466:	8082                	ret

0000000080000468 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    80000470:	c219                	beqz	a2,80000476 <printint+0xe>
    80000472:	08054063          	bltz	a0,800004f2 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    80000476:	4881                	li	a7,0
    80000478:	fc840693          	addi	a3,s0,-56

  i = 0;
    8000047c:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000047e:	00007617          	auipc	a2,0x7
    80000482:	2b260613          	addi	a2,a2,690 # 80007730 <digits>
    80000486:	883e                	mv	a6,a5
    80000488:	2785                	addiw	a5,a5,1
    8000048a:	02b57733          	remu	a4,a0,a1
    8000048e:	9732                	add	a4,a4,a2
    80000490:	00074703          	lbu	a4,0(a4)
    80000494:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000498:	872a                	mv	a4,a0
    8000049a:	02b55533          	divu	a0,a0,a1
    8000049e:	0685                	addi	a3,a3,1
    800004a0:	feb773e3          	bgeu	a4,a1,80000486 <printint+0x1e>

  if(sign)
    800004a4:	00088a63          	beqz	a7,800004b8 <printint+0x50>
    buf[i++] = '-';
    800004a8:	1781                	addi	a5,a5,-32
    800004aa:	97a2                	add	a5,a5,s0
    800004ac:	02d00713          	li	a4,45
    800004b0:	fee78423          	sb	a4,-24(a5)
    800004b4:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004b8:	02f05963          	blez	a5,800004ea <printint+0x82>
    800004bc:	f426                	sd	s1,40(sp)
    800004be:	f04a                	sd	s2,32(sp)
    800004c0:	fc840713          	addi	a4,s0,-56
    800004c4:	00f704b3          	add	s1,a4,a5
    800004c8:	fff70913          	addi	s2,a4,-1
    800004cc:	993e                	add	s2,s2,a5
    800004ce:	37fd                	addiw	a5,a5,-1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004d8:	fff4c503          	lbu	a0,-1(s1)
    800004dc:	d9dff0ef          	jal	80000278 <consputc>
  while(--i >= 0)
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	ff249be3          	bne	s1,s2,800004d8 <printint+0x70>
    800004e6:	74a2                	ld	s1,40(sp)
    800004e8:	7902                	ld	s2,32(sp)
}
    800004ea:	70e2                	ld	ra,56(sp)
    800004ec:	7442                	ld	s0,48(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4885                	li	a7,1
    x = -xx;
    800004f8:	b741                	j	80000478 <printint+0x10>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	0000a797          	auipc	a5,0xa
    8000051c:	d3c7a783          	lw	a5,-708(a5) # 8000a254 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050763          	beqz	a0,800007bc <printf+0x2c2>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4981                	li	s3,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a01d                	j	80000584 <printf+0x8a>
    acquire(&pr.lock);
    80000560:	00012517          	auipc	a0,0x12
    80000564:	dc850513          	addi	a0,a0,-568 # 80012328 <pr>
    80000568:	666000ef          	jal	80000bce <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0bff0ef          	jal	80000278 <consputc>
      continue;
    80000572:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	0014899b          	addiw	s3,s1,1
    80000578:	013a07b3          	add	a5,s4,s3
    8000057c:	0007c503          	lbu	a0,0(a5)
    80000580:	20050b63          	beqz	a0,80000796 <printf+0x29c>
    if(cx != '%'){
    80000584:	ff5515e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000588:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000058c:	009a07b3          	add	a5,s4,s1
    80000590:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20090b63          	beqz	s2,800007aa <printf+0x2b0>
    80000598:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000059c:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c789                	beqz	a5,800005a8 <printf+0xae>
    800005a0:	009a0733          	add	a4,s4,s1
    800005a4:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005a8:	03690963          	beq	s2,s6,800005da <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005ac:	05890363          	beq	s2,s8,800005f2 <printf+0xf8>
    } else if(c0 == 'u'){
    800005b0:	0d990663          	beq	s2,s9,8000067c <printf+0x182>
    } else if(c0 == 'x'){
    800005b4:	11a90d63          	beq	s2,s10,800006ce <printf+0x1d4>
    } else if(c0 == 'p'){
    800005b8:	15b90663          	beq	s2,s11,80000704 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005bc:	06300793          	li	a5,99
    800005c0:	18f90563          	beq	s2,a5,8000074a <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c4:	07300793          	li	a5,115
    800005c8:	18f90b63          	beq	s2,a5,8000075e <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005cc:	03591b63          	bne	s2,s5,80000602 <printf+0x108>
      consputc('%');
    800005d0:	02500513          	li	a0,37
    800005d4:	ca5ff0ef          	jal	80000278 <consputc>
    800005d8:	bf71                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005da:	f8843783          	ld	a5,-120(s0)
    800005de:	00878713          	addi	a4,a5,8
    800005e2:	f8e43423          	sd	a4,-120(s0)
    800005e6:	4605                	li	a2,1
    800005e8:	45a9                	li	a1,10
    800005ea:	4388                	lw	a0,0(a5)
    800005ec:	e7dff0ef          	jal	80000468 <printint>
    800005f0:	b751                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f2:	01678f63          	beq	a5,s6,80000610 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f6:	03878b63          	beq	a5,s8,8000062c <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    800005fa:	09978e63          	beq	a5,s9,80000696 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fe:	0fa78563          	beq	a5,s10,800006e8 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000602:	8556                	mv	a0,s5
    80000604:	c75ff0ef          	jal	80000278 <consputc>
      consputc(c0);
    80000608:	854a                	mv	a0,s2
    8000060a:	c6fff0ef          	jal	80000278 <consputc>
    8000060e:	b79d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000610:	f8843783          	ld	a5,-120(s0)
    80000614:	00878713          	addi	a4,a5,8
    80000618:	f8e43423          	sd	a4,-120(s0)
    8000061c:	4605                	li	a2,1
    8000061e:	45a9                	li	a1,10
    80000620:	6388                	ld	a0,0(a5)
    80000622:	e47ff0ef          	jal	80000468 <printint>
      i += 1;
    80000626:	0029849b          	addiw	s1,s3,2
    8000062a:	b7a9                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062c:	06400793          	li	a5,100
    80000630:	02f68863          	beq	a3,a5,80000660 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000634:	07500793          	li	a5,117
    80000638:	06f68d63          	beq	a3,a5,800006b2 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063c:	07800793          	li	a5,120
    80000640:	fcf691e3          	bne	a3,a5,80000602 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4601                	li	a2,0
    80000652:	45c1                	li	a1,16
    80000654:	6388                	ld	a0,0(a5)
    80000656:	e13ff0ef          	jal	80000468 <printint>
      i += 2;
    8000065a:	0039849b          	addiw	s1,s3,3
    8000065e:	bf19                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	df7ff0ef          	jal	80000468 <printint>
      i += 2;
    80000676:	0039849b          	addiw	s1,s3,3
    8000067a:	bded                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	0007e503          	lwu	a0,0(a5)
    80000690:	dd9ff0ef          	jal	80000468 <printint>
    80000694:	b5c5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4601                	li	a2,0
    800006a4:	45a9                	li	a1,10
    800006a6:	6388                	ld	a0,0(a5)
    800006a8:	dc1ff0ef          	jal	80000468 <printint>
      i += 1;
    800006ac:	0029849b          	addiw	s1,s3,2
    800006b0:	b5d1                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45a9                	li	a1,10
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	da5ff0ef          	jal	80000468 <printint>
      i += 2;
    800006c8:	0039849b          	addiw	s1,s3,3
    800006cc:	b565                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	4601                	li	a2,0
    800006dc:	45c1                	li	a1,16
    800006de:	0007e503          	lwu	a0,0(a5)
    800006e2:	d87ff0ef          	jal	80000468 <printint>
    800006e6:	b579                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	4601                	li	a2,0
    800006f6:	45c1                	li	a1,16
    800006f8:	6388                	ld	a0,0(a5)
    800006fa:	d6fff0ef          	jal	80000468 <printint>
      i += 1;
    800006fe:	0029849b          	addiw	s1,s3,2
    80000702:	bd8d                	j	80000574 <printf+0x7a>
    80000704:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000716:	03000513          	li	a0,48
    8000071a:	b5fff0ef          	jal	80000278 <consputc>
  consputc('x');
    8000071e:	07800513          	li	a0,120
    80000722:	b57ff0ef          	jal	80000278 <consputc>
    80000726:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000728:	00007b97          	auipc	s7,0x7
    8000072c:	008b8b93          	addi	s7,s7,8 # 80007730 <digits>
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	97de                	add	a5,a5,s7
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	b3fff0ef          	jal	80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073e:	0992                	slli	s3,s3,0x4
    80000740:	397d                	addiw	s2,s2,-1
    80000742:	fe0917e3          	bnez	s2,80000730 <printf+0x236>
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	b535                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000074a:	f8843783          	ld	a5,-120(s0)
    8000074e:	00878713          	addi	a4,a5,8
    80000752:	f8e43423          	sd	a4,-120(s0)
    80000756:	4388                	lw	a0,0(a5)
    80000758:	b21ff0ef          	jal	80000278 <consputc>
    8000075c:	bd21                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	0007b903          	ld	s2,0(a5)
    8000076e:	00090d63          	beqz	s2,80000788 <printf+0x28e>
      for(; *s; s++)
    80000772:	00094503          	lbu	a0,0(s2)
    80000776:	de050fe3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    8000077a:	affff0ef          	jal	80000278 <consputc>
      for(; *s; s++)
    8000077e:	0905                	addi	s2,s2,1
    80000780:	00094503          	lbu	a0,0(s2)
    80000784:	f97d                	bnez	a0,8000077a <printf+0x280>
    80000786:	b3fd                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000788:	00007917          	auipc	s2,0x7
    8000078c:	88090913          	addi	s2,s2,-1920 # 80007008 <etext+0x8>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	b7dd                	j	8000077a <printf+0x280>
    80000796:	74a6                	ld	s1,104(sp)
    80000798:	7906                	ld	s2,96(sp)
    8000079a:	69e6                	ld	s3,88(sp)
    8000079c:	6aa6                	ld	s5,72(sp)
    8000079e:	6b06                	ld	s6,64(sp)
    800007a0:	7c42                	ld	s8,48(sp)
    800007a2:	7ca2                	ld	s9,40(sp)
    800007a4:	7d02                	ld	s10,32(sp)
    800007a6:	6de2                	ld	s11,24(sp)
    800007a8:	a811                	j	800007bc <printf+0x2c2>
    800007aa:	74a6                	ld	s1,104(sp)
    800007ac:	7906                	ld	s2,96(sp)
    800007ae:	69e6                	ld	s3,88(sp)
    800007b0:	6aa6                	ld	s5,72(sp)
    800007b2:	6b06                	ld	s6,64(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007bc:	0000a797          	auipc	a5,0xa
    800007c0:	a987a783          	lw	a5,-1384(a5) # 8000a254 <panicking>
    800007c4:	c799                	beqz	a5,800007d2 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007c6:	4501                	li	a0,0
    800007c8:	70e6                	ld	ra,120(sp)
    800007ca:	7446                	ld	s0,112(sp)
    800007cc:	6a46                	ld	s4,80(sp)
    800007ce:	6129                	addi	sp,sp,192
    800007d0:	8082                	ret
    release(&pr.lock);
    800007d2:	00012517          	auipc	a0,0x12
    800007d6:	b5650513          	addi	a0,a0,-1194 # 80012328 <pr>
    800007da:	48c000ef          	jal	80000c66 <release>
  return 0;
    800007de:	b7e5                	j	800007c6 <printf+0x2cc>

00000000800007e0 <panic>:

void
panic(char *s)
{
    800007e0:	1101                	addi	sp,sp,-32
    800007e2:	ec06                	sd	ra,24(sp)
    800007e4:	e822                	sd	s0,16(sp)
    800007e6:	e426                	sd	s1,8(sp)
    800007e8:	e04a                	sd	s2,0(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  panicking = 1;
    800007ee:	4905                	li	s2,1
    800007f0:	0000a797          	auipc	a5,0xa
    800007f4:	a727a223          	sw	s2,-1436(a5) # 8000a254 <panicking>
  printf("panic: ");
    800007f8:	00007517          	auipc	a0,0x7
    800007fc:	82050513          	addi	a0,a0,-2016 # 80007018 <etext+0x18>
    80000800:	cfbff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000804:	85a6                	mv	a1,s1
    80000806:	00007517          	auipc	a0,0x7
    8000080a:	81a50513          	addi	a0,a0,-2022 # 80007020 <etext+0x20>
    8000080e:	cedff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	0000a797          	auipc	a5,0xa
    80000816:	a327af23          	sw	s2,-1474(a5) # 8000a250 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3a>

000000008000081c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000824:	00007597          	auipc	a1,0x7
    80000828:	80458593          	addi	a1,a1,-2044 # 80007028 <etext+0x28>
    8000082c:	00012517          	auipc	a0,0x12
    80000830:	afc50513          	addi	a0,a0,-1284 # 80012328 <pr>
    80000834:	31a000ef          	jal	80000b4e <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000840:	1141                	addi	sp,sp,-16
    80000842:	e406                	sd	ra,8(sp)
    80000844:	e022                	sd	s0,0(sp)
    80000846:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000848:	100007b7          	lui	a5,0x10000
    8000084c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000850:	10000737          	lui	a4,0x10000
    80000854:	f8000693          	li	a3,-128
    80000858:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085c:	468d                	li	a3,3
    8000085e:	10000637          	lui	a2,0x10000
    80000862:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000866:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000086a:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086e:	10000737          	lui	a4,0x10000
    80000872:	461d                	li	a2,7
    80000874:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000878:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    8000087c:	00006597          	auipc	a1,0x6
    80000880:	7b458593          	addi	a1,a1,1972 # 80007030 <etext+0x30>
    80000884:	00012517          	auipc	a0,0x12
    80000888:	abc50513          	addi	a0,a0,-1348 # 80012340 <tx_lock>
    8000088c:	2c2000ef          	jal	80000b4e <initlock>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000898:	715d                	addi	sp,sp,-80
    8000089a:	e486                	sd	ra,72(sp)
    8000089c:	e0a2                	sd	s0,64(sp)
    8000089e:	fc26                	sd	s1,56(sp)
    800008a0:	ec56                	sd	s5,24(sp)
    800008a2:	0880                	addi	s0,sp,80
    800008a4:	8aaa                	mv	s5,a0
    800008a6:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a8:	00012517          	auipc	a0,0x12
    800008ac:	a9850513          	addi	a0,a0,-1384 # 80012340 <tx_lock>
    800008b0:	31e000ef          	jal	80000bce <acquire>

  int i = 0;
  while(i < n){ 
    800008b4:	06905063          	blez	s1,80000914 <uartwrite+0x7c>
    800008b8:	f84a                	sd	s2,48(sp)
    800008ba:	f44e                	sd	s3,40(sp)
    800008bc:	f052                	sd	s4,32(sp)
    800008be:	e85a                	sd	s6,16(sp)
    800008c0:	e45e                	sd	s7,8(sp)
    800008c2:	8a56                	mv	s4,s5
    800008c4:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c6:	0000a497          	auipc	s1,0xa
    800008ca:	99648493          	addi	s1,s1,-1642 # 8000a25c <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	00012997          	auipc	s3,0x12
    800008d2:	a7298993          	addi	s3,s3,-1422 # 80012340 <tx_lock>
    800008d6:	0000a917          	auipc	s2,0xa
    800008da:	98290913          	addi	s2,s2,-1662 # 8000a258 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    800008de:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008e2:	4b05                	li	s6,1
    800008e4:	a005                	j	80000904 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e6:	85ce                	mv	a1,s3
    800008e8:	854a                	mv	a0,s2
    800008ea:	650010ef          	jal	80001f3a <sleep>
    while(tx_busy != 0){
    800008ee:	409c                	lw	a5,0(s1)
    800008f0:	fbfd                	bnez	a5,800008e6 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008f2:	000a4783          	lbu	a5,0(s4)
    800008f6:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008fa:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fe:	0a05                	addi	s4,s4,1
    80000900:	015a0563          	beq	s4,s5,8000090a <uartwrite+0x72>
    while(tx_busy != 0){
    80000904:	409c                	lw	a5,0(s1)
    80000906:	f3e5                	bnez	a5,800008e6 <uartwrite+0x4e>
    80000908:	b7ed                	j	800008f2 <uartwrite+0x5a>
    8000090a:	7942                	ld	s2,48(sp)
    8000090c:	79a2                	ld	s3,40(sp)
    8000090e:	7a02                	ld	s4,32(sp)
    80000910:	6b42                	ld	s6,16(sp)
    80000912:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000914:	00012517          	auipc	a0,0x12
    80000918:	a2c50513          	addi	a0,a0,-1492 # 80012340 <tx_lock>
    8000091c:	34a000ef          	jal	80000c66 <release>
}
    80000920:	60a6                	ld	ra,72(sp)
    80000922:	6406                	ld	s0,64(sp)
    80000924:	74e2                	ld	s1,56(sp)
    80000926:	6ae2                	ld	s5,24(sp)
    80000928:	6161                	addi	sp,sp,80
    8000092a:	8082                	ret

000000008000092c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000092c:	1101                	addi	sp,sp,-32
    8000092e:	ec06                	sd	ra,24(sp)
    80000930:	e822                	sd	s0,16(sp)
    80000932:	e426                	sd	s1,8(sp)
    80000934:	1000                	addi	s0,sp,32
    80000936:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000938:	0000a797          	auipc	a5,0xa
    8000093c:	91c7a783          	lw	a5,-1764(a5) # 8000a254 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	0000a797          	auipc	a5,0xa
    80000946:	90e7a783          	lw	a5,-1778(a5) # 8000a250 <panicked>
    8000094a:	ef85                	bnez	a5,80000982 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000094c:	10000737          	lui	a4,0x10000
    80000950:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000952:	00074783          	lbu	a5,0(a4)
    80000956:	0207f793          	andi	a5,a5,32
    8000095a:	dfe5                	beqz	a5,80000952 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000095c:	0ff4f513          	zext.b	a0,s1
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000968:	0000a797          	auipc	a5,0xa
    8000096c:	8ec7a783          	lw	a5,-1812(a5) # 8000a254 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	212000ef          	jal	80000b8e <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	28e000ef          	jal	80000c12 <pop_off>
}
    80000988:	b7ed                	j	80000972 <uartputc_sync+0x46>

000000008000098a <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000098a:	1141                	addi	sp,sp,-16
    8000098c:	e422                	sd	s0,8(sp)
    8000098e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000990:	100007b7          	lui	a5,0x10000
    80000994:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000996:	0007c783          	lbu	a5,0(a5)
    8000099a:	8b85                	andi	a5,a5,1
    8000099c:	cb81                	beqz	a5,800009ac <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a6:	6422                	ld	s0,8(sp)
    800009a8:	0141                	addi	sp,sp,16
    800009aa:	8082                	ret
    return -1;
    800009ac:	557d                	li	a0,-1
    800009ae:	bfe5                	j	800009a6 <uartgetc+0x1c>

00000000800009b0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009b0:	1101                	addi	sp,sp,-32
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e822                	sd	s0,16(sp)
    800009b6:	e426                	sd	s1,8(sp)
    800009b8:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009c0:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009c4:	00012517          	auipc	a0,0x12
    800009c8:	97c50513          	addi	a0,a0,-1668 # 80012340 <tx_lock>
    800009cc:	202000ef          	jal	80000bce <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009d6:	0007c783          	lbu	a5,0(a5)
    800009da:	0207f793          	andi	a5,a5,32
    800009de:	eb89                	bnez	a5,800009f0 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009e0:	00012517          	auipc	a0,0x12
    800009e4:	96050513          	addi	a0,a0,-1696 # 80012340 <tx_lock>
    800009e8:	27e000ef          	jal	80000c66 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	0000a797          	auipc	a5,0xa
    800009f4:	8607a623          	sw	zero,-1940(a5) # 8000a25c <tx_busy>
    wakeup(&tx_chan);
    800009f8:	0000a517          	auipc	a0,0xa
    800009fc:	86050513          	addi	a0,a0,-1952 # 8000a258 <tx_chan>
    80000a00:	586010ef          	jal	80001f86 <wakeup>
    80000a04:	bff1                	j	800009e0 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a06:	8a5ff0ef          	jal	800002aa <consoleintr>
    int c = uartgetc();
    80000a0a:	f81ff0ef          	jal	8000098a <uartgetc>
    if(c == -1)
    80000a0e:	fe951ce3          	bne	a0,s1,80000a06 <uartintr+0x56>
  }
}
    80000a12:	60e2                	ld	ra,24(sp)
    80000a14:	6442                	ld	s0,16(sp)
    80000a16:	64a2                	ld	s1,8(sp)
    80000a18:	6105                	addi	sp,sp,32
    80000a1a:	8082                	ret

0000000080000a1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1c:	1101                	addi	sp,sp,-32
    80000a1e:	ec06                	sd	ra,24(sp)
    80000a20:	e822                	sd	s0,16(sp)
    80000a22:	e426                	sd	s1,8(sp)
    80000a24:	e04a                	sd	s2,0(sp)
    80000a26:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a28:	03451793          	slli	a5,a0,0x34
    80000a2c:	e7a9                	bnez	a5,80000a76 <kfree+0x5a>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	00023797          	auipc	a5,0x23
    80000a34:	d5878793          	addi	a5,a5,-680 # 80023788 <end>
    80000a38:	02f56f63          	bltu	a0,a5,80000a76 <kfree+0x5a>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	02f57b63          	bgeu	a0,a5,80000a76 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	25a000ef          	jal	80000ca2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	00012917          	auipc	s2,0x12
    80000a50:	90c90913          	addi	s2,s2,-1780 # 80012358 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	178000ef          	jal	80000bce <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a64:	854a                	mv	a0,s2
    80000a66:	200000ef          	jal	80000c66 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00006517          	auipc	a0,0x6
    80000a7a:	5c250513          	addi	a0,a0,1474 # 80007038 <etext+0x38>
    80000a7e:	d63ff0ef          	jal	800007e0 <panic>

0000000080000a82 <freerange>:
{
    80000a82:	7179                	addi	sp,sp,-48
    80000a84:	f406                	sd	ra,40(sp)
    80000a86:	f022                	sd	s0,32(sp)
    80000a88:	ec26                	sd	s1,24(sp)
    80000a8a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a8c:	6785                	lui	a5,0x1
    80000a8e:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a92:	00e504b3          	add	s1,a0,a4
    80000a96:	777d                	lui	a4,0xfffff
    80000a98:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94be                	add	s1,s1,a5
    80000a9c:	0295e263          	bltu	a1,s1,80000ac0 <freerange+0x3e>
    80000aa0:	e84a                	sd	s2,16(sp)
    80000aa2:	e44e                	sd	s3,8(sp)
    80000aa4:	e052                	sd	s4,0(sp)
    80000aa6:	892e                	mv	s2,a1
    kfree(p);
    80000aa8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aaa:	6985                	lui	s3,0x1
    kfree(p);
    80000aac:	01448533          	add	a0,s1,s4
    80000ab0:	f6dff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe997be3          	bgeu	s2,s1,80000aac <freerange+0x2a>
    80000aba:	6942                	ld	s2,16(sp)
    80000abc:	69a2                	ld	s3,8(sp)
    80000abe:	6a02                	ld	s4,0(sp)
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad2:	00006597          	auipc	a1,0x6
    80000ad6:	56e58593          	addi	a1,a1,1390 # 80007040 <etext+0x40>
    80000ada:	00012517          	auipc	a0,0x12
    80000ade:	87e50513          	addi	a0,a0,-1922 # 80012358 <kmem>
    80000ae2:	06c000ef          	jal	80000b4e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	00023517          	auipc	a0,0x23
    80000aee:	c9e50513          	addi	a0,a0,-866 # 80023788 <end>
    80000af2:	f91ff0ef          	jal	80000a82 <freerange>
}
    80000af6:	60a2                	ld	ra,8(sp)
    80000af8:	6402                	ld	s0,0(sp)
    80000afa:	0141                	addi	sp,sp,16
    80000afc:	8082                	ret

0000000080000afe <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afe:	1101                	addi	sp,sp,-32
    80000b00:	ec06                	sd	ra,24(sp)
    80000b02:	e822                	sd	s0,16(sp)
    80000b04:	e426                	sd	s1,8(sp)
    80000b06:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b08:	00012497          	auipc	s1,0x12
    80000b0c:	85048493          	addi	s1,s1,-1968 # 80012358 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0bc000ef          	jal	80000bce <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00012517          	auipc	a0,0x12
    80000b20:	83c50513          	addi	a0,a0,-1988 # 80012358 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	140000ef          	jal	80000c66 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	172000ef          	jal	80000ca2 <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	00012517          	auipc	a0,0x12
    80000b44:	81850513          	addi	a0,a0,-2024 # 80012358 <kmem>
    80000b48:	11e000ef          	jal	80000c66 <release>
  if(r)
    80000b4c:	b7e5                	j	80000b34 <kalloc+0x36>

0000000080000b4e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b4e:	1141                	addi	sp,sp,-16
    80000b50:	e422                	sd	s0,8(sp)
    80000b52:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b5a:	00053823          	sd	zero,16(a0)
}
    80000b5e:	6422                	ld	s0,8(sp)
    80000b60:	0141                	addi	sp,sp,16
    80000b62:	8082                	ret

0000000080000b64 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b64:	411c                	lw	a5,0(a0)
    80000b66:	e399                	bnez	a5,80000b6c <holding+0x8>
    80000b68:	4501                	li	a0,0
  return r;
}
    80000b6a:	8082                	ret
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b76:	6904                	ld	s1,16(a0)
    80000b78:	53b000ef          	jal	800018b2 <mycpu>
    80000b7c:	40a48533          	sub	a0,s1,a0
    80000b80:	00153513          	seqz	a0,a0
}
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret

0000000080000b8e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b98:	100024f3          	csrr	s1,sstatus
    80000b9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ba0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ba2:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000ba6:	50d000ef          	jal	800018b2 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cb99                	beqz	a5,80000bc2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	505000ef          	jal	800018b2 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	4f1000ef          	jal	800018b2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc6:	8085                	srli	s1,s1,0x1
    80000bc8:	8885                	andi	s1,s1,1
    80000bca:	dd64                	sw	s1,124(a0)
    80000bcc:	b7cd                	j	80000bae <push_off+0x20>

0000000080000bce <acquire>:
{
    80000bce:	1101                	addi	sp,sp,-32
    80000bd0:	ec06                	sd	ra,24(sp)
    80000bd2:	e822                	sd	s0,16(sp)
    80000bd4:	e426                	sd	s1,8(sp)
    80000bd6:	1000                	addi	s0,sp,32
    80000bd8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bda:	fb5ff0ef          	jal	80000b8e <push_off>
  if(holding(lk))
    80000bde:	8526                	mv	a0,s1
    80000be0:	f85ff0ef          	jal	80000b64 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	4705                	li	a4,1
  if(holding(lk))
    80000be6:	e105                	bnez	a0,80000c06 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be8:	87ba                	mv	a5,a4
    80000bea:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bee:	2781                	sext.w	a5,a5
    80000bf0:	ffe5                	bnez	a5,80000be8 <acquire+0x1a>
  __sync_synchronize();
    80000bf2:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000bf6:	4bd000ef          	jal	800018b2 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00006517          	auipc	a0,0x6
    80000c0a:	44250513          	addi	a0,a0,1090 # 80007048 <etext+0x48>
    80000c0e:	bd3ff0ef          	jal	800007e0 <panic>

0000000080000c12 <pop_off>:

void
pop_off(void)
{
    80000c12:	1141                	addi	sp,sp,-16
    80000c14:	e406                	sd	ra,8(sp)
    80000c16:	e022                	sd	s0,0(sp)
    80000c18:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1a:	499000ef          	jal	800018b2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c22:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c24:	e78d                	bnez	a5,80000c4e <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c26:	5d3c                	lw	a5,120(a0)
    80000c28:	02f05963          	blez	a5,80000c5a <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c2c:	37fd                	addiw	a5,a5,-1
    80000c2e:	0007871b          	sext.w	a4,a5
    80000c32:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c34:	eb09                	bnez	a4,80000c46 <pop_off+0x34>
    80000c36:	5d7c                	lw	a5,124(a0)
    80000c38:	c799                	beqz	a5,80000c46 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c42:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c46:	60a2                	ld	ra,8(sp)
    80000c48:	6402                	ld	s0,0(sp)
    80000c4a:	0141                	addi	sp,sp,16
    80000c4c:	8082                	ret
    panic("pop_off - interruptible");
    80000c4e:	00006517          	auipc	a0,0x6
    80000c52:	40250513          	addi	a0,a0,1026 # 80007050 <etext+0x50>
    80000c56:	b8bff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000c5a:	00006517          	auipc	a0,0x6
    80000c5e:	40e50513          	addi	a0,a0,1038 # 80007068 <etext+0x68>
    80000c62:	b7fff0ef          	jal	800007e0 <panic>

0000000080000c66 <release>:
{
    80000c66:	1101                	addi	sp,sp,-32
    80000c68:	ec06                	sd	ra,24(sp)
    80000c6a:	e822                	sd	s0,16(sp)
    80000c6c:	e426                	sd	s1,8(sp)
    80000c6e:	1000                	addi	s0,sp,32
    80000c70:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c72:	ef3ff0ef          	jal	80000b64 <holding>
    80000c76:	c105                	beqz	a0,80000c96 <release+0x30>
  lk->cpu = 0;
    80000c78:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c7c:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000c80:	0310000f          	fence	rw,w
    80000c84:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000c88:	f8bff0ef          	jal	80000c12 <pop_off>
}
    80000c8c:	60e2                	ld	ra,24(sp)
    80000c8e:	6442                	ld	s0,16(sp)
    80000c90:	64a2                	ld	s1,8(sp)
    80000c92:	6105                	addi	sp,sp,32
    80000c94:	8082                	ret
    panic("release");
    80000c96:	00006517          	auipc	a0,0x6
    80000c9a:	3da50513          	addi	a0,a0,986 # 80007070 <etext+0x70>
    80000c9e:	b43ff0ef          	jal	800007e0 <panic>

0000000080000ca2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ca2:	1141                	addi	sp,sp,-16
    80000ca4:	e422                	sd	s0,8(sp)
    80000ca6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ca8:	ca19                	beqz	a2,80000cbe <memset+0x1c>
    80000caa:	87aa                	mv	a5,a0
    80000cac:	1602                	slli	a2,a2,0x20
    80000cae:	9201                	srli	a2,a2,0x20
    80000cb0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cb4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cb8:	0785                	addi	a5,a5,1
    80000cba:	fee79de3          	bne	a5,a4,80000cb4 <memset+0x12>
  }
  return dst;
}
    80000cbe:	6422                	ld	s0,8(sp)
    80000cc0:	0141                	addi	sp,sp,16
    80000cc2:	8082                	ret

0000000080000cc4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cc4:	1141                	addi	sp,sp,-16
    80000cc6:	e422                	sd	s0,8(sp)
    80000cc8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cca:	ca05                	beqz	a2,80000cfa <memcmp+0x36>
    80000ccc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cd0:	1682                	slli	a3,a3,0x20
    80000cd2:	9281                	srli	a3,a3,0x20
    80000cd4:	0685                	addi	a3,a3,1
    80000cd6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cd8:	00054783          	lbu	a5,0(a0)
    80000cdc:	0005c703          	lbu	a4,0(a1)
    80000ce0:	00e79863          	bne	a5,a4,80000cf0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ce4:	0505                	addi	a0,a0,1
    80000ce6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ce8:	fed518e3          	bne	a0,a3,80000cd8 <memcmp+0x14>
  }

  return 0;
    80000cec:	4501                	li	a0,0
    80000cee:	a019                	j	80000cf4 <memcmp+0x30>
      return *s1 - *s2;
    80000cf0:	40e7853b          	subw	a0,a5,a4
}
    80000cf4:	6422                	ld	s0,8(sp)
    80000cf6:	0141                	addi	sp,sp,16
    80000cf8:	8082                	ret
  return 0;
    80000cfa:	4501                	li	a0,0
    80000cfc:	bfe5                	j	80000cf4 <memcmp+0x30>

0000000080000cfe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000cfe:	1141                	addi	sp,sp,-16
    80000d00:	e422                	sd	s0,8(sp)
    80000d02:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d04:	c205                	beqz	a2,80000d24 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d06:	02a5e263          	bltu	a1,a0,80000d2a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d0a:	1602                	slli	a2,a2,0x20
    80000d0c:	9201                	srli	a2,a2,0x20
    80000d0e:	00c587b3          	add	a5,a1,a2
{
    80000d12:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d14:	0585                	addi	a1,a1,1
    80000d16:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdb879>
    80000d18:	fff5c683          	lbu	a3,-1(a1)
    80000d1c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d20:	feb79ae3          	bne	a5,a1,80000d14 <memmove+0x16>

  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  if(s < d && s + n > d){
    80000d2a:	02061693          	slli	a3,a2,0x20
    80000d2e:	9281                	srli	a3,a3,0x20
    80000d30:	00d58733          	add	a4,a1,a3
    80000d34:	fce57be3          	bgeu	a0,a4,80000d0a <memmove+0xc>
    d += n;
    80000d38:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d3a:	fff6079b          	addiw	a5,a2,-1
    80000d3e:	1782                	slli	a5,a5,0x20
    80000d40:	9381                	srli	a5,a5,0x20
    80000d42:	fff7c793          	not	a5,a5
    80000d46:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d48:	177d                	addi	a4,a4,-1
    80000d4a:	16fd                	addi	a3,a3,-1
    80000d4c:	00074603          	lbu	a2,0(a4)
    80000d50:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d54:	fef71ae3          	bne	a4,a5,80000d48 <memmove+0x4a>
    80000d58:	b7f1                	j	80000d24 <memmove+0x26>

0000000080000d5a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d5a:	1141                	addi	sp,sp,-16
    80000d5c:	e406                	sd	ra,8(sp)
    80000d5e:	e022                	sd	s0,0(sp)
    80000d60:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d62:	f9dff0ef          	jal	80000cfe <memmove>
}
    80000d66:	60a2                	ld	ra,8(sp)
    80000d68:	6402                	ld	s0,0(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret

0000000080000d6e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d74:	ce11                	beqz	a2,80000d90 <strncmp+0x22>
    80000d76:	00054783          	lbu	a5,0(a0)
    80000d7a:	cf89                	beqz	a5,80000d94 <strncmp+0x26>
    80000d7c:	0005c703          	lbu	a4,0(a1)
    80000d80:	00f71a63          	bne	a4,a5,80000d94 <strncmp+0x26>
    n--, p++, q++;
    80000d84:	367d                	addiw	a2,a2,-1
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d8a:	f675                	bnez	a2,80000d76 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	a801                	j	80000d9e <strncmp+0x30>
    80000d90:	4501                	li	a0,0
    80000d92:	a031                	j	80000d9e <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000d94:	00054503          	lbu	a0,0(a0)
    80000d98:	0005c783          	lbu	a5,0(a1)
    80000d9c:	9d1d                	subw	a0,a0,a5
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret

0000000080000da4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000da4:	1141                	addi	sp,sp,-16
    80000da6:	e422                	sd	s0,8(sp)
    80000da8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000daa:	87aa                	mv	a5,a0
    80000dac:	86b2                	mv	a3,a2
    80000dae:	367d                	addiw	a2,a2,-1
    80000db0:	02d05563          	blez	a3,80000dda <strncpy+0x36>
    80000db4:	0785                	addi	a5,a5,1
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	fee78fa3          	sb	a4,-1(a5)
    80000dbe:	0585                	addi	a1,a1,1
    80000dc0:	f775                	bnez	a4,80000dac <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dc2:	873e                	mv	a4,a5
    80000dc4:	9fb5                	addw	a5,a5,a3
    80000dc6:	37fd                	addiw	a5,a5,-1
    80000dc8:	00c05963          	blez	a2,80000dda <strncpy+0x36>
    *s++ = 0;
    80000dcc:	0705                	addi	a4,a4,1
    80000dce:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000dd2:	40e786bb          	subw	a3,a5,a4
    80000dd6:	fed04be3          	bgtz	a3,80000dcc <strncpy+0x28>
  return os;
}
    80000dda:	6422                	ld	s0,8(sp)
    80000ddc:	0141                	addi	sp,sp,16
    80000dde:	8082                	ret

0000000080000de0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000de6:	02c05363          	blez	a2,80000e0c <safestrcpy+0x2c>
    80000dea:	fff6069b          	addiw	a3,a2,-1
    80000dee:	1682                	slli	a3,a3,0x20
    80000df0:	9281                	srli	a3,a3,0x20
    80000df2:	96ae                	add	a3,a3,a1
    80000df4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000df6:	00d58963          	beq	a1,a3,80000e08 <safestrcpy+0x28>
    80000dfa:	0585                	addi	a1,a1,1
    80000dfc:	0785                	addi	a5,a5,1
    80000dfe:	fff5c703          	lbu	a4,-1(a1)
    80000e02:	fee78fa3          	sb	a4,-1(a5)
    80000e06:	fb65                	bnez	a4,80000df6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e08:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret

0000000080000e12 <strlen>:

int
strlen(const char *s)
{
    80000e12:	1141                	addi	sp,sp,-16
    80000e14:	e422                	sd	s0,8(sp)
    80000e16:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e18:	00054783          	lbu	a5,0(a0)
    80000e1c:	cf91                	beqz	a5,80000e38 <strlen+0x26>
    80000e1e:	0505                	addi	a0,a0,1
    80000e20:	87aa                	mv	a5,a0
    80000e22:	86be                	mv	a3,a5
    80000e24:	0785                	addi	a5,a5,1
    80000e26:	fff7c703          	lbu	a4,-1(a5)
    80000e2a:	ff65                	bnez	a4,80000e22 <strlen+0x10>
    80000e2c:	40a6853b          	subw	a0,a3,a0
    80000e30:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <strlen+0x20>

0000000080000e3c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e406                	sd	ra,8(sp)
    80000e40:	e022                	sd	s0,0(sp)
    80000e42:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e44:	25f000ef          	jal	800018a2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e48:	00009717          	auipc	a4,0x9
    80000e4c:	41870713          	addi	a4,a4,1048 # 8000a260 <started>
  if(cpuid() == 0){
    80000e50:	c51d                	beqz	a0,80000e7e <main+0x42>
    while(started == 0)
    80000e52:	431c                	lw	a5,0(a4)
    80000e54:	2781                	sext.w	a5,a5
    80000e56:	dff5                	beqz	a5,80000e52 <main+0x16>
      ;
    __sync_synchronize();
    80000e58:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000e5c:	247000ef          	jal	800018a2 <cpuid>
    80000e60:	85aa                	mv	a1,a0
    80000e62:	00006517          	auipc	a0,0x6
    80000e66:	23650513          	addi	a0,a0,566 # 80007098 <etext+0x98>
    80000e6a:	e90ff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000e6e:	080000ef          	jal	80000eee <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e72:	650010ef          	jal	800024c2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e76:	6c2040ef          	jal	80005538 <plicinithart>
  }

  scheduler();        
    80000e7a:	6cb000ef          	jal	80001d44 <scheduler>
    consoleinit();
    80000e7e:	da6ff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000e82:	99bff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000e86:	00006517          	auipc	a0,0x6
    80000e8a:	1f250513          	addi	a0,a0,498 # 80007078 <etext+0x78>
    80000e8e:	e6cff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000e92:	00006517          	auipc	a0,0x6
    80000e96:	1ee50513          	addi	a0,a0,494 # 80007080 <etext+0x80>
    80000e9a:	e60ff0ef          	jal	800004fa <printf>
    printf("\n");
    80000e9e:	00006517          	auipc	a0,0x6
    80000ea2:	1da50513          	addi	a0,a0,474 # 80007078 <etext+0x78>
    80000ea6:	e54ff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000eaa:	c21ff0ef          	jal	80000aca <kinit>
    kvminit();       // create kernel page table
    80000eae:	2ca000ef          	jal	80001178 <kvminit>
    kvminithart();   // turn on paging
    80000eb2:	03c000ef          	jal	80000eee <kvminithart>
    procinit();      // process table
    80000eb6:	137000ef          	jal	800017ec <procinit>
    trapinit();      // trap vectors
    80000eba:	5e4010ef          	jal	8000249e <trapinit>
    trapinithart();  // install kernel trap vector
    80000ebe:	604010ef          	jal	800024c2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ec2:	65c040ef          	jal	8000551e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ec6:	672040ef          	jal	80005538 <plicinithart>
    binit();         // buffer cache
    80000eca:	531010ef          	jal	80002bfa <binit>
    iinit();         // inode table
    80000ece:	2b6020ef          	jal	80003184 <iinit>
    fileinit();      // file table
    80000ed2:	1a8030ef          	jal	8000407a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ed6:	752040ef          	jal	80005628 <virtio_disk_init>
    userinit();      // first user process
    80000eda:	4bf000ef          	jal	80001b98 <userinit>
    __sync_synchronize();
    80000ede:	0330000f          	fence	rw,rw
    started = 1;
    80000ee2:	4785                	li	a5,1
    80000ee4:	00009717          	auipc	a4,0x9
    80000ee8:	36f72e23          	sw	a5,892(a4) # 8000a260 <started>
    80000eec:	b779                	j	80000e7a <main+0x3e>

0000000080000eee <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000eee:	1141                	addi	sp,sp,-16
    80000ef0:	e422                	sd	s0,8(sp)
    80000ef2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ef4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ef8:	00009797          	auipc	a5,0x9
    80000efc:	3707b783          	ld	a5,880(a5) # 8000a268 <kernel_pagetable>
    80000f00:	83b1                	srli	a5,a5,0xc
    80000f02:	577d                	li	a4,-1
    80000f04:	177e                	slli	a4,a4,0x3f
    80000f06:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f08:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f0c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret

0000000080000f16 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f16:	7139                	addi	sp,sp,-64
    80000f18:	fc06                	sd	ra,56(sp)
    80000f1a:	f822                	sd	s0,48(sp)
    80000f1c:	f426                	sd	s1,40(sp)
    80000f1e:	f04a                	sd	s2,32(sp)
    80000f20:	ec4e                	sd	s3,24(sp)
    80000f22:	e852                	sd	s4,16(sp)
    80000f24:	e456                	sd	s5,8(sp)
    80000f26:	e05a                	sd	s6,0(sp)
    80000f28:	0080                	addi	s0,sp,64
    80000f2a:	84aa                	mv	s1,a0
    80000f2c:	89ae                	mv	s3,a1
    80000f2e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f30:	57fd                	li	a5,-1
    80000f32:	83e9                	srli	a5,a5,0x1a
    80000f34:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f36:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f38:	02b7fc63          	bgeu	a5,a1,80000f70 <walk+0x5a>
    panic("walk");
    80000f3c:	00006517          	auipc	a0,0x6
    80000f40:	17450513          	addi	a0,a0,372 # 800070b0 <etext+0xb0>
    80000f44:	89dff0ef          	jal	800007e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f48:	060a8263          	beqz	s5,80000fac <walk+0x96>
    80000f4c:	bb3ff0ef          	jal	80000afe <kalloc>
    80000f50:	84aa                	mv	s1,a0
    80000f52:	c139                	beqz	a0,80000f98 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f54:	6605                	lui	a2,0x1
    80000f56:	4581                	li	a1,0
    80000f58:	d4bff0ef          	jal	80000ca2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f5c:	00c4d793          	srli	a5,s1,0xc
    80000f60:	07aa                	slli	a5,a5,0xa
    80000f62:	0017e793          	ori	a5,a5,1
    80000f66:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000f6a:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdb86f>
    80000f6c:	036a0063          	beq	s4,s6,80000f8c <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000f70:	0149d933          	srl	s2,s3,s4
    80000f74:	1ff97913          	andi	s2,s2,511
    80000f78:	090e                	slli	s2,s2,0x3
    80000f7a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000f7c:	00093483          	ld	s1,0(s2)
    80000f80:	0014f793          	andi	a5,s1,1
    80000f84:	d3f1                	beqz	a5,80000f48 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000f86:	80a9                	srli	s1,s1,0xa
    80000f88:	04b2                	slli	s1,s1,0xc
    80000f8a:	b7c5                	j	80000f6a <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000f8c:	00c9d513          	srli	a0,s3,0xc
    80000f90:	1ff57513          	andi	a0,a0,511
    80000f94:	050e                	slli	a0,a0,0x3
    80000f96:	9526                	add	a0,a0,s1
}
    80000f98:	70e2                	ld	ra,56(sp)
    80000f9a:	7442                	ld	s0,48(sp)
    80000f9c:	74a2                	ld	s1,40(sp)
    80000f9e:	7902                	ld	s2,32(sp)
    80000fa0:	69e2                	ld	s3,24(sp)
    80000fa2:	6a42                	ld	s4,16(sp)
    80000fa4:	6aa2                	ld	s5,8(sp)
    80000fa6:	6b02                	ld	s6,0(sp)
    80000fa8:	6121                	addi	sp,sp,64
    80000faa:	8082                	ret
        return 0;
    80000fac:	4501                	li	a0,0
    80000fae:	b7ed                	j	80000f98 <walk+0x82>

0000000080000fb0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fb0:	57fd                	li	a5,-1
    80000fb2:	83e9                	srli	a5,a5,0x1a
    80000fb4:	00b7f463          	bgeu	a5,a1,80000fbc <walkaddr+0xc>
    return 0;
    80000fb8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000fba:	8082                	ret
{
    80000fbc:	1141                	addi	sp,sp,-16
    80000fbe:	e406                	sd	ra,8(sp)
    80000fc0:	e022                	sd	s0,0(sp)
    80000fc2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000fc4:	4601                	li	a2,0
    80000fc6:	f51ff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    80000fca:	c105                	beqz	a0,80000fea <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000fcc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000fce:	0117f693          	andi	a3,a5,17
    80000fd2:	4745                	li	a4,17
    return 0;
    80000fd4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000fd6:	00e68663          	beq	a3,a4,80000fe2 <walkaddr+0x32>
}
    80000fda:	60a2                	ld	ra,8(sp)
    80000fdc:	6402                	ld	s0,0(sp)
    80000fde:	0141                	addi	sp,sp,16
    80000fe0:	8082                	ret
  pa = PTE2PA(*pte);
    80000fe2:	83a9                	srli	a5,a5,0xa
    80000fe4:	00c79513          	slli	a0,a5,0xc
  return pa;
    80000fe8:	bfcd                	j	80000fda <walkaddr+0x2a>
    return 0;
    80000fea:	4501                	li	a0,0
    80000fec:	b7fd                	j	80000fda <walkaddr+0x2a>

0000000080000fee <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80000fee:	715d                	addi	sp,sp,-80
    80000ff0:	e486                	sd	ra,72(sp)
    80000ff2:	e0a2                	sd	s0,64(sp)
    80000ff4:	fc26                	sd	s1,56(sp)
    80000ff6:	f84a                	sd	s2,48(sp)
    80000ff8:	f44e                	sd	s3,40(sp)
    80000ffa:	f052                	sd	s4,32(sp)
    80000ffc:	ec56                	sd	s5,24(sp)
    80000ffe:	e85a                	sd	s6,16(sp)
    80001000:	e45e                	sd	s7,8(sp)
    80001002:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001004:	03459793          	slli	a5,a1,0x34
    80001008:	e7a9                	bnez	a5,80001052 <mappages+0x64>
    8000100a:	8aaa                	mv	s5,a0
    8000100c:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000100e:	03461793          	slli	a5,a2,0x34
    80001012:	e7b1                	bnez	a5,8000105e <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80001014:	ca39                	beqz	a2,8000106a <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001016:	77fd                	lui	a5,0xfffff
    80001018:	963e                	add	a2,a2,a5
    8000101a:	00b609b3          	add	s3,a2,a1
  a = va;
    8000101e:	892e                	mv	s2,a1
    80001020:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001024:	6b85                	lui	s7,0x1
    80001026:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    8000102a:	4605                	li	a2,1
    8000102c:	85ca                	mv	a1,s2
    8000102e:	8556                	mv	a0,s5
    80001030:	ee7ff0ef          	jal	80000f16 <walk>
    80001034:	c539                	beqz	a0,80001082 <mappages+0x94>
    if(*pte & PTE_V)
    80001036:	611c                	ld	a5,0(a0)
    80001038:	8b85                	andi	a5,a5,1
    8000103a:	ef95                	bnez	a5,80001076 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000103c:	80b1                	srli	s1,s1,0xc
    8000103e:	04aa                	slli	s1,s1,0xa
    80001040:	0164e4b3          	or	s1,s1,s6
    80001044:	0014e493          	ori	s1,s1,1
    80001048:	e104                	sd	s1,0(a0)
    if(a == last)
    8000104a:	05390863          	beq	s2,s3,8000109a <mappages+0xac>
    a += PGSIZE;
    8000104e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001050:	bfd9                	j	80001026 <mappages+0x38>
    panic("mappages: va not aligned");
    80001052:	00006517          	auipc	a0,0x6
    80001056:	06650513          	addi	a0,a0,102 # 800070b8 <etext+0xb8>
    8000105a:	f86ff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    8000105e:	00006517          	auipc	a0,0x6
    80001062:	07a50513          	addi	a0,a0,122 # 800070d8 <etext+0xd8>
    80001066:	f7aff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    8000106a:	00006517          	auipc	a0,0x6
    8000106e:	08e50513          	addi	a0,a0,142 # 800070f8 <etext+0xf8>
    80001072:	f6eff0ef          	jal	800007e0 <panic>
      panic("mappages: remap");
    80001076:	00006517          	auipc	a0,0x6
    8000107a:	09250513          	addi	a0,a0,146 # 80007108 <etext+0x108>
    8000107e:	f62ff0ef          	jal	800007e0 <panic>
      return -1;
    80001082:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001084:	60a6                	ld	ra,72(sp)
    80001086:	6406                	ld	s0,64(sp)
    80001088:	74e2                	ld	s1,56(sp)
    8000108a:	7942                	ld	s2,48(sp)
    8000108c:	79a2                	ld	s3,40(sp)
    8000108e:	7a02                	ld	s4,32(sp)
    80001090:	6ae2                	ld	s5,24(sp)
    80001092:	6b42                	ld	s6,16(sp)
    80001094:	6ba2                	ld	s7,8(sp)
    80001096:	6161                	addi	sp,sp,80
    80001098:	8082                	ret
  return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7e5                	j	80001084 <mappages+0x96>

000000008000109e <kvmmap>:
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
    800010a6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010a8:	86b2                	mv	a3,a2
    800010aa:	863e                	mv	a2,a5
    800010ac:	f43ff0ef          	jal	80000fee <mappages>
    800010b0:	e509                	bnez	a0,800010ba <kvmmap+0x1c>
}
    800010b2:	60a2                	ld	ra,8(sp)
    800010b4:	6402                	ld	s0,0(sp)
    800010b6:	0141                	addi	sp,sp,16
    800010b8:	8082                	ret
    panic("kvmmap");
    800010ba:	00006517          	auipc	a0,0x6
    800010be:	05e50513          	addi	a0,a0,94 # 80007118 <etext+0x118>
    800010c2:	f1eff0ef          	jal	800007e0 <panic>

00000000800010c6 <kvmmake>:
{
    800010c6:	1101                	addi	sp,sp,-32
    800010c8:	ec06                	sd	ra,24(sp)
    800010ca:	e822                	sd	s0,16(sp)
    800010cc:	e426                	sd	s1,8(sp)
    800010ce:	e04a                	sd	s2,0(sp)
    800010d0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800010d2:	a2dff0ef          	jal	80000afe <kalloc>
    800010d6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800010d8:	6605                	lui	a2,0x1
    800010da:	4581                	li	a1,0
    800010dc:	bc7ff0ef          	jal	80000ca2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800010e0:	4719                	li	a4,6
    800010e2:	6685                	lui	a3,0x1
    800010e4:	10000637          	lui	a2,0x10000
    800010e8:	100005b7          	lui	a1,0x10000
    800010ec:	8526                	mv	a0,s1
    800010ee:	fb1ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800010f2:	4719                	li	a4,6
    800010f4:	6685                	lui	a3,0x1
    800010f6:	10001637          	lui	a2,0x10001
    800010fa:	100015b7          	lui	a1,0x10001
    800010fe:	8526                	mv	a0,s1
    80001100:	f9fff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001104:	4719                	li	a4,6
    80001106:	040006b7          	lui	a3,0x4000
    8000110a:	0c000637          	lui	a2,0xc000
    8000110e:	0c0005b7          	lui	a1,0xc000
    80001112:	8526                	mv	a0,s1
    80001114:	f8bff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001118:	00006917          	auipc	s2,0x6
    8000111c:	ee890913          	addi	s2,s2,-280 # 80007000 <etext>
    80001120:	4729                	li	a4,10
    80001122:	80006697          	auipc	a3,0x80006
    80001126:	ede68693          	addi	a3,a3,-290 # 7000 <_entry-0x7fff9000>
    8000112a:	4605                	li	a2,1
    8000112c:	067e                	slli	a2,a2,0x1f
    8000112e:	85b2                	mv	a1,a2
    80001130:	8526                	mv	a0,s1
    80001132:	f6dff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001136:	46c5                	li	a3,17
    80001138:	06ee                	slli	a3,a3,0x1b
    8000113a:	4719                	li	a4,6
    8000113c:	412686b3          	sub	a3,a3,s2
    80001140:	864a                	mv	a2,s2
    80001142:	85ca                	mv	a1,s2
    80001144:	8526                	mv	a0,s1
    80001146:	f59ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000114a:	4729                	li	a4,10
    8000114c:	6685                	lui	a3,0x1
    8000114e:	00005617          	auipc	a2,0x5
    80001152:	eb260613          	addi	a2,a2,-334 # 80006000 <_trampoline>
    80001156:	040005b7          	lui	a1,0x4000
    8000115a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000115c:	05b2                	slli	a1,a1,0xc
    8000115e:	8526                	mv	a0,s1
    80001160:	f3fff0ef          	jal	8000109e <kvmmap>
  proc_mapstacks(kpgtbl);
    80001164:	8526                	mv	a0,s1
    80001166:	5ee000ef          	jal	80001754 <proc_mapstacks>
}
    8000116a:	8526                	mv	a0,s1
    8000116c:	60e2                	ld	ra,24(sp)
    8000116e:	6442                	ld	s0,16(sp)
    80001170:	64a2                	ld	s1,8(sp)
    80001172:	6902                	ld	s2,0(sp)
    80001174:	6105                	addi	sp,sp,32
    80001176:	8082                	ret

0000000080001178 <kvminit>:
{
    80001178:	1141                	addi	sp,sp,-16
    8000117a:	e406                	sd	ra,8(sp)
    8000117c:	e022                	sd	s0,0(sp)
    8000117e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001180:	f47ff0ef          	jal	800010c6 <kvmmake>
    80001184:	00009797          	auipc	a5,0x9
    80001188:	0ea7b223          	sd	a0,228(a5) # 8000a268 <kernel_pagetable>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret

0000000080001194 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001194:	1101                	addi	sp,sp,-32
    80001196:	ec06                	sd	ra,24(sp)
    80001198:	e822                	sd	s0,16(sp)
    8000119a:	e426                	sd	s1,8(sp)
    8000119c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000119e:	961ff0ef          	jal	80000afe <kalloc>
    800011a2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011a4:	c509                	beqz	a0,800011ae <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	af9ff0ef          	jal	80000ca2 <memset>
  return pagetable;
}
    800011ae:	8526                	mv	a0,s1
    800011b0:	60e2                	ld	ra,24(sp)
    800011b2:	6442                	ld	s0,16(sp)
    800011b4:	64a2                	ld	s1,8(sp)
    800011b6:	6105                	addi	sp,sp,32
    800011b8:	8082                	ret

00000000800011ba <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011ba:	7139                	addi	sp,sp,-64
    800011bc:	fc06                	sd	ra,56(sp)
    800011be:	f822                	sd	s0,48(sp)
    800011c0:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011c2:	03459793          	slli	a5,a1,0x34
    800011c6:	e38d                	bnez	a5,800011e8 <uvmunmap+0x2e>
    800011c8:	f04a                	sd	s2,32(sp)
    800011ca:	ec4e                	sd	s3,24(sp)
    800011cc:	e852                	sd	s4,16(sp)
    800011ce:	e456                	sd	s5,8(sp)
    800011d0:	e05a                	sd	s6,0(sp)
    800011d2:	8a2a                	mv	s4,a0
    800011d4:	892e                	mv	s2,a1
    800011d6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800011d8:	0632                	slli	a2,a2,0xc
    800011da:	00b609b3          	add	s3,a2,a1
    800011de:	6b05                	lui	s6,0x1
    800011e0:	0535f963          	bgeu	a1,s3,80001232 <uvmunmap+0x78>
    800011e4:	f426                	sd	s1,40(sp)
    800011e6:	a015                	j	8000120a <uvmunmap+0x50>
    800011e8:	f426                	sd	s1,40(sp)
    800011ea:	f04a                	sd	s2,32(sp)
    800011ec:	ec4e                	sd	s3,24(sp)
    800011ee:	e852                	sd	s4,16(sp)
    800011f0:	e456                	sd	s5,8(sp)
    800011f2:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    800011f4:	00006517          	auipc	a0,0x6
    800011f8:	f2c50513          	addi	a0,a0,-212 # 80007120 <etext+0x120>
    800011fc:	de4ff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001200:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001204:	995a                	add	s2,s2,s6
    80001206:	03397563          	bgeu	s2,s3,80001230 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    8000120a:	4601                	li	a2,0
    8000120c:	85ca                	mv	a1,s2
    8000120e:	8552                	mv	a0,s4
    80001210:	d07ff0ef          	jal	80000f16 <walk>
    80001214:	84aa                	mv	s1,a0
    80001216:	d57d                	beqz	a0,80001204 <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001218:	611c                	ld	a5,0(a0)
    8000121a:	0017f713          	andi	a4,a5,1
    8000121e:	d37d                	beqz	a4,80001204 <uvmunmap+0x4a>
    if(do_free){
    80001220:	fe0a80e3          	beqz	s5,80001200 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    80001224:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001226:	00c79513          	slli	a0,a5,0xc
    8000122a:	ff2ff0ef          	jal	80000a1c <kfree>
    8000122e:	bfc9                	j	80001200 <uvmunmap+0x46>
    80001230:	74a2                	ld	s1,40(sp)
    80001232:	7902                	ld	s2,32(sp)
    80001234:	69e2                	ld	s3,24(sp)
    80001236:	6a42                	ld	s4,16(sp)
    80001238:	6aa2                	ld	s5,8(sp)
    8000123a:	6b02                	ld	s6,0(sp)
  }
}
    8000123c:	70e2                	ld	ra,56(sp)
    8000123e:	7442                	ld	s0,48(sp)
    80001240:	6121                	addi	sp,sp,64
    80001242:	8082                	ret

0000000080001244 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001244:	1101                	addi	sp,sp,-32
    80001246:	ec06                	sd	ra,24(sp)
    80001248:	e822                	sd	s0,16(sp)
    8000124a:	e426                	sd	s1,8(sp)
    8000124c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000124e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001250:	00b67d63          	bgeu	a2,a1,8000126a <uvmdealloc+0x26>
    80001254:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001256:	6785                	lui	a5,0x1
    80001258:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000125a:	00f60733          	add	a4,a2,a5
    8000125e:	76fd                	lui	a3,0xfffff
    80001260:	8f75                	and	a4,a4,a3
    80001262:	97ae                	add	a5,a5,a1
    80001264:	8ff5                	and	a5,a5,a3
    80001266:	00f76863          	bltu	a4,a5,80001276 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000126a:	8526                	mv	a0,s1
    8000126c:	60e2                	ld	ra,24(sp)
    8000126e:	6442                	ld	s0,16(sp)
    80001270:	64a2                	ld	s1,8(sp)
    80001272:	6105                	addi	sp,sp,32
    80001274:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001276:	8f99                	sub	a5,a5,a4
    80001278:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000127a:	4685                	li	a3,1
    8000127c:	0007861b          	sext.w	a2,a5
    80001280:	85ba                	mv	a1,a4
    80001282:	f39ff0ef          	jal	800011ba <uvmunmap>
    80001286:	b7d5                	j	8000126a <uvmdealloc+0x26>

0000000080001288 <uvmalloc>:
  if(newsz < oldsz)
    80001288:	08b66f63          	bltu	a2,a1,80001326 <uvmalloc+0x9e>
{
    8000128c:	7139                	addi	sp,sp,-64
    8000128e:	fc06                	sd	ra,56(sp)
    80001290:	f822                	sd	s0,48(sp)
    80001292:	ec4e                	sd	s3,24(sp)
    80001294:	e852                	sd	s4,16(sp)
    80001296:	e456                	sd	s5,8(sp)
    80001298:	0080                	addi	s0,sp,64
    8000129a:	8aaa                	mv	s5,a0
    8000129c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000129e:	6785                	lui	a5,0x1
    800012a0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012a2:	95be                	add	a1,a1,a5
    800012a4:	77fd                	lui	a5,0xfffff
    800012a6:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012aa:	08c9f063          	bgeu	s3,a2,8000132a <uvmalloc+0xa2>
    800012ae:	f426                	sd	s1,40(sp)
    800012b0:	f04a                	sd	s2,32(sp)
    800012b2:	e05a                	sd	s6,0(sp)
    800012b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012ba:	845ff0ef          	jal	80000afe <kalloc>
    800012be:	84aa                	mv	s1,a0
    if(mem == 0){
    800012c0:	c515                	beqz	a0,800012ec <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012c2:	6605                	lui	a2,0x1
    800012c4:	4581                	li	a1,0
    800012c6:	9ddff0ef          	jal	80000ca2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012ca:	875a                	mv	a4,s6
    800012cc:	86a6                	mv	a3,s1
    800012ce:	6605                	lui	a2,0x1
    800012d0:	85ca                	mv	a1,s2
    800012d2:	8556                	mv	a0,s5
    800012d4:	d1bff0ef          	jal	80000fee <mappages>
    800012d8:	e915                	bnez	a0,8000130c <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012da:	6785                	lui	a5,0x1
    800012dc:	993e                	add	s2,s2,a5
    800012de:	fd496ee3          	bltu	s2,s4,800012ba <uvmalloc+0x32>
  return newsz;
    800012e2:	8552                	mv	a0,s4
    800012e4:	74a2                	ld	s1,40(sp)
    800012e6:	7902                	ld	s2,32(sp)
    800012e8:	6b02                	ld	s6,0(sp)
    800012ea:	a811                	j	800012fe <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    800012ec:	864e                	mv	a2,s3
    800012ee:	85ca                	mv	a1,s2
    800012f0:	8556                	mv	a0,s5
    800012f2:	f53ff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    800012f6:	4501                	li	a0,0
    800012f8:	74a2                	ld	s1,40(sp)
    800012fa:	7902                	ld	s2,32(sp)
    800012fc:	6b02                	ld	s6,0(sp)
}
    800012fe:	70e2                	ld	ra,56(sp)
    80001300:	7442                	ld	s0,48(sp)
    80001302:	69e2                	ld	s3,24(sp)
    80001304:	6a42                	ld	s4,16(sp)
    80001306:	6aa2                	ld	s5,8(sp)
    80001308:	6121                	addi	sp,sp,64
    8000130a:	8082                	ret
      kfree(mem);
    8000130c:	8526                	mv	a0,s1
    8000130e:	f0eff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001312:	864e                	mv	a2,s3
    80001314:	85ca                	mv	a1,s2
    80001316:	8556                	mv	a0,s5
    80001318:	f2dff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    8000131c:	4501                	li	a0,0
    8000131e:	74a2                	ld	s1,40(sp)
    80001320:	7902                	ld	s2,32(sp)
    80001322:	6b02                	ld	s6,0(sp)
    80001324:	bfe9                	j	800012fe <uvmalloc+0x76>
    return oldsz;
    80001326:	852e                	mv	a0,a1
}
    80001328:	8082                	ret
  return newsz;
    8000132a:	8532                	mv	a0,a2
    8000132c:	bfc9                	j	800012fe <uvmalloc+0x76>

000000008000132e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000132e:	7179                	addi	sp,sp,-48
    80001330:	f406                	sd	ra,40(sp)
    80001332:	f022                	sd	s0,32(sp)
    80001334:	ec26                	sd	s1,24(sp)
    80001336:	e84a                	sd	s2,16(sp)
    80001338:	e44e                	sd	s3,8(sp)
    8000133a:	e052                	sd	s4,0(sp)
    8000133c:	1800                	addi	s0,sp,48
    8000133e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001340:	84aa                	mv	s1,a0
    80001342:	6905                	lui	s2,0x1
    80001344:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001346:	4985                	li	s3,1
    80001348:	a819                	j	8000135e <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000134a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000134c:	00c79513          	slli	a0,a5,0xc
    80001350:	fdfff0ef          	jal	8000132e <freewalk>
      pagetable[i] = 0;
    80001354:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001358:	04a1                	addi	s1,s1,8
    8000135a:	01248f63          	beq	s1,s2,80001378 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    8000135e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001360:	00f7f713          	andi	a4,a5,15
    80001364:	ff3703e3          	beq	a4,s3,8000134a <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001368:	8b85                	andi	a5,a5,1
    8000136a:	d7fd                	beqz	a5,80001358 <freewalk+0x2a>
      panic("freewalk: leaf");
    8000136c:	00006517          	auipc	a0,0x6
    80001370:	dcc50513          	addi	a0,a0,-564 # 80007138 <etext+0x138>
    80001374:	c6cff0ef          	jal	800007e0 <panic>
    }
  }
  kfree((void*)pagetable);
    80001378:	8552                	mv	a0,s4
    8000137a:	ea2ff0ef          	jal	80000a1c <kfree>
}
    8000137e:	70a2                	ld	ra,40(sp)
    80001380:	7402                	ld	s0,32(sp)
    80001382:	64e2                	ld	s1,24(sp)
    80001384:	6942                	ld	s2,16(sp)
    80001386:	69a2                	ld	s3,8(sp)
    80001388:	6a02                	ld	s4,0(sp)
    8000138a:	6145                	addi	sp,sp,48
    8000138c:	8082                	ret

000000008000138e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000138e:	1101                	addi	sp,sp,-32
    80001390:	ec06                	sd	ra,24(sp)
    80001392:	e822                	sd	s0,16(sp)
    80001394:	e426                	sd	s1,8(sp)
    80001396:	1000                	addi	s0,sp,32
    80001398:	84aa                	mv	s1,a0
  if(sz > 0)
    8000139a:	e989                	bnez	a1,800013ac <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000139c:	8526                	mv	a0,s1
    8000139e:	f91ff0ef          	jal	8000132e <freewalk>
}
    800013a2:	60e2                	ld	ra,24(sp)
    800013a4:	6442                	ld	s0,16(sp)
    800013a6:	64a2                	ld	s1,8(sp)
    800013a8:	6105                	addi	sp,sp,32
    800013aa:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013ac:	6785                	lui	a5,0x1
    800013ae:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013b0:	95be                	add	a1,a1,a5
    800013b2:	4685                	li	a3,1
    800013b4:	00c5d613          	srli	a2,a1,0xc
    800013b8:	4581                	li	a1,0
    800013ba:	e01ff0ef          	jal	800011ba <uvmunmap>
    800013be:	bff9                	j	8000139c <uvmfree+0xe>

00000000800013c0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013c0:	ce49                	beqz	a2,8000145a <uvmcopy+0x9a>
{
    800013c2:	715d                	addi	sp,sp,-80
    800013c4:	e486                	sd	ra,72(sp)
    800013c6:	e0a2                	sd	s0,64(sp)
    800013c8:	fc26                	sd	s1,56(sp)
    800013ca:	f84a                	sd	s2,48(sp)
    800013cc:	f44e                	sd	s3,40(sp)
    800013ce:	f052                	sd	s4,32(sp)
    800013d0:	ec56                	sd	s5,24(sp)
    800013d2:	e85a                	sd	s6,16(sp)
    800013d4:	e45e                	sd	s7,8(sp)
    800013d6:	0880                	addi	s0,sp,80
    800013d8:	8aaa                	mv	s5,a0
    800013da:	8b2e                	mv	s6,a1
    800013dc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800013de:	4481                	li	s1,0
    800013e0:	a029                	j	800013ea <uvmcopy+0x2a>
    800013e2:	6785                	lui	a5,0x1
    800013e4:	94be                	add	s1,s1,a5
    800013e6:	0544fe63          	bgeu	s1,s4,80001442 <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    800013ea:	4601                	li	a2,0
    800013ec:	85a6                	mv	a1,s1
    800013ee:	8556                	mv	a0,s5
    800013f0:	b27ff0ef          	jal	80000f16 <walk>
    800013f4:	d57d                	beqz	a0,800013e2 <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    800013f6:	6118                	ld	a4,0(a0)
    800013f8:	00177793          	andi	a5,a4,1
    800013fc:	d3fd                	beqz	a5,800013e2 <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    800013fe:	00a75593          	srli	a1,a4,0xa
    80001402:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001406:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000140a:	ef4ff0ef          	jal	80000afe <kalloc>
    8000140e:	89aa                	mv	s3,a0
    80001410:	c105                	beqz	a0,80001430 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001412:	6605                	lui	a2,0x1
    80001414:	85de                	mv	a1,s7
    80001416:	8e9ff0ef          	jal	80000cfe <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000141a:	874a                	mv	a4,s2
    8000141c:	86ce                	mv	a3,s3
    8000141e:	6605                	lui	a2,0x1
    80001420:	85a6                	mv	a1,s1
    80001422:	855a                	mv	a0,s6
    80001424:	bcbff0ef          	jal	80000fee <mappages>
    80001428:	dd4d                	beqz	a0,800013e2 <uvmcopy+0x22>
      kfree(mem);
    8000142a:	854e                	mv	a0,s3
    8000142c:	df0ff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001430:	4685                	li	a3,1
    80001432:	00c4d613          	srli	a2,s1,0xc
    80001436:	4581                	li	a1,0
    80001438:	855a                	mv	a0,s6
    8000143a:	d81ff0ef          	jal	800011ba <uvmunmap>
  return -1;
    8000143e:	557d                	li	a0,-1
    80001440:	a011                	j	80001444 <uvmcopy+0x84>
  return 0;
    80001442:	4501                	li	a0,0
}
    80001444:	60a6                	ld	ra,72(sp)
    80001446:	6406                	ld	s0,64(sp)
    80001448:	74e2                	ld	s1,56(sp)
    8000144a:	7942                	ld	s2,48(sp)
    8000144c:	79a2                	ld	s3,40(sp)
    8000144e:	7a02                	ld	s4,32(sp)
    80001450:	6ae2                	ld	s5,24(sp)
    80001452:	6b42                	ld	s6,16(sp)
    80001454:	6ba2                	ld	s7,8(sp)
    80001456:	6161                	addi	sp,sp,80
    80001458:	8082                	ret
  return 0;
    8000145a:	4501                	li	a0,0
}
    8000145c:	8082                	ret

000000008000145e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000145e:	1141                	addi	sp,sp,-16
    80001460:	e406                	sd	ra,8(sp)
    80001462:	e022                	sd	s0,0(sp)
    80001464:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001466:	4601                	li	a2,0
    80001468:	aafff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    8000146c:	c901                	beqz	a0,8000147c <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000146e:	611c                	ld	a5,0(a0)
    80001470:	9bbd                	andi	a5,a5,-17
    80001472:	e11c                	sd	a5,0(a0)
}
    80001474:	60a2                	ld	ra,8(sp)
    80001476:	6402                	ld	s0,0(sp)
    80001478:	0141                	addi	sp,sp,16
    8000147a:	8082                	ret
    panic("uvmclear");
    8000147c:	00006517          	auipc	a0,0x6
    80001480:	ccc50513          	addi	a0,a0,-820 # 80007148 <etext+0x148>
    80001484:	b5cff0ef          	jal	800007e0 <panic>

0000000080001488 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001488:	c6dd                	beqz	a3,80001536 <copyinstr+0xae>
{
    8000148a:	715d                	addi	sp,sp,-80
    8000148c:	e486                	sd	ra,72(sp)
    8000148e:	e0a2                	sd	s0,64(sp)
    80001490:	fc26                	sd	s1,56(sp)
    80001492:	f84a                	sd	s2,48(sp)
    80001494:	f44e                	sd	s3,40(sp)
    80001496:	f052                	sd	s4,32(sp)
    80001498:	ec56                	sd	s5,24(sp)
    8000149a:	e85a                	sd	s6,16(sp)
    8000149c:	e45e                	sd	s7,8(sp)
    8000149e:	0880                	addi	s0,sp,80
    800014a0:	8a2a                	mv	s4,a0
    800014a2:	8b2e                	mv	s6,a1
    800014a4:	8bb2                	mv	s7,a2
    800014a6:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014a8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014aa:	6985                	lui	s3,0x1
    800014ac:	a825                	j	800014e4 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014ae:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014b4:	37fd                	addiw	a5,a5,-1
    800014b6:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014ba:	60a6                	ld	ra,72(sp)
    800014bc:	6406                	ld	s0,64(sp)
    800014be:	74e2                	ld	s1,56(sp)
    800014c0:	7942                	ld	s2,48(sp)
    800014c2:	79a2                	ld	s3,40(sp)
    800014c4:	7a02                	ld	s4,32(sp)
    800014c6:	6ae2                	ld	s5,24(sp)
    800014c8:	6b42                	ld	s6,16(sp)
    800014ca:	6ba2                	ld	s7,8(sp)
    800014cc:	6161                	addi	sp,sp,80
    800014ce:	8082                	ret
    800014d0:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    800014d4:	9742                	add	a4,a4,a6
      --max;
    800014d6:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    800014da:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    800014de:	04e58463          	beq	a1,a4,80001526 <copyinstr+0x9e>
{
    800014e2:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    800014e4:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800014e8:	85a6                	mv	a1,s1
    800014ea:	8552                	mv	a0,s4
    800014ec:	ac5ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0)
    800014f0:	cd0d                	beqz	a0,8000152a <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800014f2:	417486b3          	sub	a3,s1,s7
    800014f6:	96ce                	add	a3,a3,s3
    if(n > max)
    800014f8:	00d97363          	bgeu	s2,a3,800014fe <copyinstr+0x76>
    800014fc:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    800014fe:	955e                	add	a0,a0,s7
    80001500:	8d05                	sub	a0,a0,s1
    while(n > 0){
    80001502:	c695                	beqz	a3,8000152e <copyinstr+0xa6>
    80001504:	87da                	mv	a5,s6
    80001506:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001508:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000150c:	96da                	add	a3,a3,s6
    8000150e:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001510:	00f60733          	add	a4,a2,a5
    80001514:	00074703          	lbu	a4,0(a4)
    80001518:	db59                	beqz	a4,800014ae <copyinstr+0x26>
        *dst = *p;
    8000151a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000151e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001520:	fed797e3          	bne	a5,a3,8000150e <copyinstr+0x86>
    80001524:	b775                	j	800014d0 <copyinstr+0x48>
    80001526:	4781                	li	a5,0
    80001528:	b771                	j	800014b4 <copyinstr+0x2c>
      return -1;
    8000152a:	557d                	li	a0,-1
    8000152c:	b779                	j	800014ba <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    8000152e:	6b85                	lui	s7,0x1
    80001530:	9ba6                	add	s7,s7,s1
    80001532:	87da                	mv	a5,s6
    80001534:	b77d                	j	800014e2 <copyinstr+0x5a>
  int got_null = 0;
    80001536:	4781                	li	a5,0
  if(got_null){
    80001538:	37fd                	addiw	a5,a5,-1
    8000153a:	0007851b          	sext.w	a0,a5
}
    8000153e:	8082                	ret

0000000080001540 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001540:	1141                	addi	sp,sp,-16
    80001542:	e406                	sd	ra,8(sp)
    80001544:	e022                	sd	s0,0(sp)
    80001546:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001548:	4601                	li	a2,0
    8000154a:	9cdff0ef          	jal	80000f16 <walk>
  if (pte == 0) {
    8000154e:	c519                	beqz	a0,8000155c <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001550:	6108                	ld	a0,0(a0)
    80001552:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80001554:	60a2                	ld	ra,8(sp)
    80001556:	6402                	ld	s0,0(sp)
    80001558:	0141                	addi	sp,sp,16
    8000155a:	8082                	ret
    return 0;
    8000155c:	4501                	li	a0,0
    8000155e:	bfdd                	j	80001554 <ismapped+0x14>

0000000080001560 <vmfault>:
{
    80001560:	7179                	addi	sp,sp,-48
    80001562:	f406                	sd	ra,40(sp)
    80001564:	f022                	sd	s0,32(sp)
    80001566:	ec26                	sd	s1,24(sp)
    80001568:	e44e                	sd	s3,8(sp)
    8000156a:	1800                	addi	s0,sp,48
    8000156c:	89aa                	mv	s3,a0
    8000156e:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80001570:	35e000ef          	jal	800018ce <myproc>
  if (va >= p->sz)
    80001574:	653c                	ld	a5,72(a0)
    80001576:	00f4ea63          	bltu	s1,a5,8000158a <vmfault+0x2a>
    return 0;
    8000157a:	4981                	li	s3,0
}
    8000157c:	854e                	mv	a0,s3
    8000157e:	70a2                	ld	ra,40(sp)
    80001580:	7402                	ld	s0,32(sp)
    80001582:	64e2                	ld	s1,24(sp)
    80001584:	69a2                	ld	s3,8(sp)
    80001586:	6145                	addi	sp,sp,48
    80001588:	8082                	ret
    8000158a:	e84a                	sd	s2,16(sp)
    8000158c:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    8000158e:	77fd                	lui	a5,0xfffff
    80001590:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    80001592:	85a6                	mv	a1,s1
    80001594:	854e                	mv	a0,s3
    80001596:	fabff0ef          	jal	80001540 <ismapped>
    return 0;
    8000159a:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    8000159c:	c119                	beqz	a0,800015a2 <vmfault+0x42>
    8000159e:	6942                	ld	s2,16(sp)
    800015a0:	bff1                	j	8000157c <vmfault+0x1c>
    800015a2:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015a4:	d5aff0ef          	jal	80000afe <kalloc>
    800015a8:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015aa:	c90d                	beqz	a0,800015dc <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015ac:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	4581                	li	a1,0
    800015b2:	ef0ff0ef          	jal	80000ca2 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015b6:	4759                	li	a4,22
    800015b8:	86d2                	mv	a3,s4
    800015ba:	6605                	lui	a2,0x1
    800015bc:	85a6                	mv	a1,s1
    800015be:	05093503          	ld	a0,80(s2)
    800015c2:	a2dff0ef          	jal	80000fee <mappages>
    800015c6:	e501                	bnez	a0,800015ce <vmfault+0x6e>
    800015c8:	6942                	ld	s2,16(sp)
    800015ca:	6a02                	ld	s4,0(sp)
    800015cc:	bf45                	j	8000157c <vmfault+0x1c>
    kfree((void *)mem);
    800015ce:	8552                	mv	a0,s4
    800015d0:	c4cff0ef          	jal	80000a1c <kfree>
    return 0;
    800015d4:	4981                	li	s3,0
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	6a02                	ld	s4,0(sp)
    800015da:	b74d                	j	8000157c <vmfault+0x1c>
    800015dc:	6942                	ld	s2,16(sp)
    800015de:	6a02                	ld	s4,0(sp)
    800015e0:	bf71                	j	8000157c <vmfault+0x1c>

00000000800015e2 <copyout>:
  while(len > 0){
    800015e2:	c2cd                	beqz	a3,80001684 <copyout+0xa2>
{
    800015e4:	711d                	addi	sp,sp,-96
    800015e6:	ec86                	sd	ra,88(sp)
    800015e8:	e8a2                	sd	s0,80(sp)
    800015ea:	e4a6                	sd	s1,72(sp)
    800015ec:	f852                	sd	s4,48(sp)
    800015ee:	f05a                	sd	s6,32(sp)
    800015f0:	ec5e                	sd	s7,24(sp)
    800015f2:	e862                	sd	s8,16(sp)
    800015f4:	1080                	addi	s0,sp,96
    800015f6:	8c2a                	mv	s8,a0
    800015f8:	8b2e                	mv	s6,a1
    800015fa:	8bb2                	mv	s7,a2
    800015fc:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800015fe:	74fd                	lui	s1,0xfffff
    80001600:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001602:	57fd                	li	a5,-1
    80001604:	83e9                	srli	a5,a5,0x1a
    80001606:	0897e163          	bltu	a5,s1,80001688 <copyout+0xa6>
    8000160a:	e0ca                	sd	s2,64(sp)
    8000160c:	fc4e                	sd	s3,56(sp)
    8000160e:	f456                	sd	s5,40(sp)
    80001610:	e466                	sd	s9,8(sp)
    80001612:	e06a                	sd	s10,0(sp)
    80001614:	6d05                	lui	s10,0x1
    80001616:	8cbe                	mv	s9,a5
    80001618:	a015                	j	8000163c <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000161a:	409b0533          	sub	a0,s6,s1
    8000161e:	0009861b          	sext.w	a2,s3
    80001622:	85de                	mv	a1,s7
    80001624:	954a                	add	a0,a0,s2
    80001626:	ed8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000162a:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000162e:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001630:	040a0363          	beqz	s4,80001676 <copyout+0x94>
    if(va0 >= MAXVA)
    80001634:	055cec63          	bltu	s9,s5,8000168c <copyout+0xaa>
    80001638:	84d6                	mv	s1,s5
    8000163a:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    8000163c:	85a6                	mv	a1,s1
    8000163e:	8562                	mv	a0,s8
    80001640:	971ff0ef          	jal	80000fb0 <walkaddr>
    80001644:	892a                	mv	s2,a0
    if(pa0 == 0) {
    80001646:	e901                	bnez	a0,80001656 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001648:	4601                	li	a2,0
    8000164a:	85a6                	mv	a1,s1
    8000164c:	8562                	mv	a0,s8
    8000164e:	f13ff0ef          	jal	80001560 <vmfault>
    80001652:	892a                	mv	s2,a0
    80001654:	c139                	beqz	a0,8000169a <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    80001656:	4601                	li	a2,0
    80001658:	85a6                	mv	a1,s1
    8000165a:	8562                	mv	a0,s8
    8000165c:	8bbff0ef          	jal	80000f16 <walk>
    if((*pte & PTE_W) == 0)
    80001660:	611c                	ld	a5,0(a0)
    80001662:	8b91                	andi	a5,a5,4
    80001664:	c3b1                	beqz	a5,800016a8 <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    80001666:	01a48ab3          	add	s5,s1,s10
    8000166a:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    8000166e:	fb3a76e3          	bgeu	s4,s3,8000161a <copyout+0x38>
    80001672:	89d2                	mv	s3,s4
    80001674:	b75d                	j	8000161a <copyout+0x38>
  return 0;
    80001676:	4501                	li	a0,0
    80001678:	6906                	ld	s2,64(sp)
    8000167a:	79e2                	ld	s3,56(sp)
    8000167c:	7aa2                	ld	s5,40(sp)
    8000167e:	6ca2                	ld	s9,8(sp)
    80001680:	6d02                	ld	s10,0(sp)
    80001682:	a80d                	j	800016b4 <copyout+0xd2>
    80001684:	4501                	li	a0,0
}
    80001686:	8082                	ret
      return -1;
    80001688:	557d                	li	a0,-1
    8000168a:	a02d                	j	800016b4 <copyout+0xd2>
    8000168c:	557d                	li	a0,-1
    8000168e:	6906                	ld	s2,64(sp)
    80001690:	79e2                	ld	s3,56(sp)
    80001692:	7aa2                	ld	s5,40(sp)
    80001694:	6ca2                	ld	s9,8(sp)
    80001696:	6d02                	ld	s10,0(sp)
    80001698:	a831                	j	800016b4 <copyout+0xd2>
        return -1;
    8000169a:	557d                	li	a0,-1
    8000169c:	6906                	ld	s2,64(sp)
    8000169e:	79e2                	ld	s3,56(sp)
    800016a0:	7aa2                	ld	s5,40(sp)
    800016a2:	6ca2                	ld	s9,8(sp)
    800016a4:	6d02                	ld	s10,0(sp)
    800016a6:	a039                	j	800016b4 <copyout+0xd2>
      return -1;
    800016a8:	557d                	li	a0,-1
    800016aa:	6906                	ld	s2,64(sp)
    800016ac:	79e2                	ld	s3,56(sp)
    800016ae:	7aa2                	ld	s5,40(sp)
    800016b0:	6ca2                	ld	s9,8(sp)
    800016b2:	6d02                	ld	s10,0(sp)
}
    800016b4:	60e6                	ld	ra,88(sp)
    800016b6:	6446                	ld	s0,80(sp)
    800016b8:	64a6                	ld	s1,72(sp)
    800016ba:	7a42                	ld	s4,48(sp)
    800016bc:	7b02                	ld	s6,32(sp)
    800016be:	6be2                	ld	s7,24(sp)
    800016c0:	6c42                	ld	s8,16(sp)
    800016c2:	6125                	addi	sp,sp,96
    800016c4:	8082                	ret

00000000800016c6 <copyin>:
  while(len > 0){
    800016c6:	c6c9                	beqz	a3,80001750 <copyin+0x8a>
{
    800016c8:	715d                	addi	sp,sp,-80
    800016ca:	e486                	sd	ra,72(sp)
    800016cc:	e0a2                	sd	s0,64(sp)
    800016ce:	fc26                	sd	s1,56(sp)
    800016d0:	f84a                	sd	s2,48(sp)
    800016d2:	f44e                	sd	s3,40(sp)
    800016d4:	f052                	sd	s4,32(sp)
    800016d6:	ec56                	sd	s5,24(sp)
    800016d8:	e85a                	sd	s6,16(sp)
    800016da:	e45e                	sd	s7,8(sp)
    800016dc:	e062                	sd	s8,0(sp)
    800016de:	0880                	addi	s0,sp,80
    800016e0:	8baa                	mv	s7,a0
    800016e2:	8aae                	mv	s5,a1
    800016e4:	8932                	mv	s2,a2
    800016e6:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    800016e8:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    800016ea:	6b05                	lui	s6,0x1
    800016ec:	a035                	j	80001718 <copyin+0x52>
    800016ee:	412984b3          	sub	s1,s3,s2
    800016f2:	94da                	add	s1,s1,s6
    if(n > len)
    800016f4:	009a7363          	bgeu	s4,s1,800016fa <copyin+0x34>
    800016f8:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016fa:	413905b3          	sub	a1,s2,s3
    800016fe:	0004861b          	sext.w	a2,s1
    80001702:	95aa                	add	a1,a1,a0
    80001704:	8556                	mv	a0,s5
    80001706:	df8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000170a:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000170e:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001710:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001714:	020a0163          	beqz	s4,80001736 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001718:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000171c:	85ce                	mv	a1,s3
    8000171e:	855e                	mv	a0,s7
    80001720:	891ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0) {
    80001724:	f569                	bnez	a0,800016ee <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001726:	4601                	li	a2,0
    80001728:	85ce                	mv	a1,s3
    8000172a:	855e                	mv	a0,s7
    8000172c:	e35ff0ef          	jal	80001560 <vmfault>
    80001730:	fd5d                	bnez	a0,800016ee <copyin+0x28>
        return -1;
    80001732:	557d                	li	a0,-1
    80001734:	a011                	j	80001738 <copyin+0x72>
  return 0;
    80001736:	4501                	li	a0,0
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6c02                	ld	s8,0(sp)
    8000174c:	6161                	addi	sp,sp,80
    8000174e:	8082                	ret
  return 0;
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret

0000000080001754 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001754:	7139                	addi	sp,sp,-64
    80001756:	fc06                	sd	ra,56(sp)
    80001758:	f822                	sd	s0,48(sp)
    8000175a:	f426                	sd	s1,40(sp)
    8000175c:	f04a                	sd	s2,32(sp)
    8000175e:	ec4e                	sd	s3,24(sp)
    80001760:	e852                	sd	s4,16(sp)
    80001762:	e456                	sd	s5,8(sp)
    80001764:	e05a                	sd	s6,0(sp)
    80001766:	0080                	addi	s0,sp,64
    80001768:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000176a:	00011497          	auipc	s1,0x11
    8000176e:	03e48493          	addi	s1,s1,62 # 800127a8 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001772:	8b26                	mv	s6,s1
    80001774:	ff4df937          	lui	s2,0xff4df
    80001778:	9bd90913          	addi	s2,s2,-1603 # ffffffffff4de9bd <end+0xffffffff7f4bb235>
    8000177c:	0936                	slli	s2,s2,0xd
    8000177e:	6f590913          	addi	s2,s2,1781
    80001782:	0936                	slli	s2,s2,0xd
    80001784:	bd390913          	addi	s2,s2,-1069
    80001788:	0932                	slli	s2,s2,0xc
    8000178a:	7a790913          	addi	s2,s2,1959
    8000178e:	040009b7          	lui	s3,0x4000
    80001792:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001794:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001796:	00017a97          	auipc	s5,0x17
    8000179a:	c12a8a93          	addi	s5,s5,-1006 # 800183a8 <tickslock>
    char *pa = kalloc();
    8000179e:	b60ff0ef          	jal	80000afe <kalloc>
    800017a2:	862a                	mv	a2,a0
    if(pa == 0)
    800017a4:	cd15                	beqz	a0,800017e0 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int) (p - proc));
    800017a6:	416485b3          	sub	a1,s1,s6
    800017aa:	8591                	srai	a1,a1,0x4
    800017ac:	032585b3          	mul	a1,a1,s2
    800017b0:	2585                	addiw	a1,a1,1
    800017b2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017b6:	4719                	li	a4,6
    800017b8:	6685                	lui	a3,0x1
    800017ba:	40b985b3          	sub	a1,s3,a1
    800017be:	8552                	mv	a0,s4
    800017c0:	8dfff0ef          	jal	8000109e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017c4:	17048493          	addi	s1,s1,368
    800017c8:	fd549be3          	bne	s1,s5,8000179e <proc_mapstacks+0x4a>
  }
}
    800017cc:	70e2                	ld	ra,56(sp)
    800017ce:	7442                	ld	s0,48(sp)
    800017d0:	74a2                	ld	s1,40(sp)
    800017d2:	7902                	ld	s2,32(sp)
    800017d4:	69e2                	ld	s3,24(sp)
    800017d6:	6a42                	ld	s4,16(sp)
    800017d8:	6aa2                	ld	s5,8(sp)
    800017da:	6b02                	ld	s6,0(sp)
    800017dc:	6121                	addi	sp,sp,64
    800017de:	8082                	ret
      panic("kalloc");
    800017e0:	00006517          	auipc	a0,0x6
    800017e4:	97850513          	addi	a0,a0,-1672 # 80007158 <etext+0x158>
    800017e8:	ff9fe0ef          	jal	800007e0 <panic>

00000000800017ec <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800017ec:	7139                	addi	sp,sp,-64
    800017ee:	fc06                	sd	ra,56(sp)
    800017f0:	f822                	sd	s0,48(sp)
    800017f2:	f426                	sd	s1,40(sp)
    800017f4:	f04a                	sd	s2,32(sp)
    800017f6:	ec4e                	sd	s3,24(sp)
    800017f8:	e852                	sd	s4,16(sp)
    800017fa:	e456                	sd	s5,8(sp)
    800017fc:	e05a                	sd	s6,0(sp)
    800017fe:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001800:	00006597          	auipc	a1,0x6
    80001804:	96058593          	addi	a1,a1,-1696 # 80007160 <etext+0x160>
    80001808:	00011517          	auipc	a0,0x11
    8000180c:	b7050513          	addi	a0,a0,-1168 # 80012378 <pid_lock>
    80001810:	b3eff0ef          	jal	80000b4e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001814:	00006597          	auipc	a1,0x6
    80001818:	95458593          	addi	a1,a1,-1708 # 80007168 <etext+0x168>
    8000181c:	00011517          	auipc	a0,0x11
    80001820:	b7450513          	addi	a0,a0,-1164 # 80012390 <wait_lock>
    80001824:	b2aff0ef          	jal	80000b4e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001828:	00011497          	auipc	s1,0x11
    8000182c:	f8048493          	addi	s1,s1,-128 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001830:	00006b17          	auipc	s6,0x6
    80001834:	948b0b13          	addi	s6,s6,-1720 # 80007178 <etext+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001838:	8aa6                	mv	s5,s1
    8000183a:	ff4df937          	lui	s2,0xff4df
    8000183e:	9bd90913          	addi	s2,s2,-1603 # ffffffffff4de9bd <end+0xffffffff7f4bb235>
    80001842:	0936                	slli	s2,s2,0xd
    80001844:	6f590913          	addi	s2,s2,1781
    80001848:	0936                	slli	s2,s2,0xd
    8000184a:	bd390913          	addi	s2,s2,-1069
    8000184e:	0932                	slli	s2,s2,0xc
    80001850:	7a790913          	addi	s2,s2,1959
    80001854:	040009b7          	lui	s3,0x4000
    80001858:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000185a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00017a17          	auipc	s4,0x17
    80001860:	b4ca0a13          	addi	s4,s4,-1204 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001864:	85da                	mv	a1,s6
    80001866:	8526                	mv	a0,s1
    80001868:	ae6ff0ef          	jal	80000b4e <initlock>
      p->state = UNUSED;
    8000186c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001870:	415487b3          	sub	a5,s1,s5
    80001874:	8791                	srai	a5,a5,0x4
    80001876:	032787b3          	mul	a5,a5,s2
    8000187a:	2785                	addiw	a5,a5,1 # fffffffffffff001 <end+0xffffffff7ffdb879>
    8000187c:	00d7979b          	slliw	a5,a5,0xd
    80001880:	40f987b3          	sub	a5,s3,a5
    80001884:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001886:	17048493          	addi	s1,s1,368
    8000188a:	fd449de3          	bne	s1,s4,80001864 <procinit+0x78>
  }
}
    8000188e:	70e2                	ld	ra,56(sp)
    80001890:	7442                	ld	s0,48(sp)
    80001892:	74a2                	ld	s1,40(sp)
    80001894:	7902                	ld	s2,32(sp)
    80001896:	69e2                	ld	s3,24(sp)
    80001898:	6a42                	ld	s4,16(sp)
    8000189a:	6aa2                	ld	s5,8(sp)
    8000189c:	6b02                	ld	s6,0(sp)
    8000189e:	6121                	addi	sp,sp,64
    800018a0:	8082                	ret

00000000800018a2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018a2:	1141                	addi	sp,sp,-16
    800018a4:	e422                	sd	s0,8(sp)
    800018a6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018a8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018aa:	2501                	sext.w	a0,a0
    800018ac:	6422                	ld	s0,8(sp)
    800018ae:	0141                	addi	sp,sp,16
    800018b0:	8082                	ret

00000000800018b2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018b2:	1141                	addi	sp,sp,-16
    800018b4:	e422                	sd	s0,8(sp)
    800018b6:	0800                	addi	s0,sp,16
    800018b8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018ba:	2781                	sext.w	a5,a5
    800018bc:	079e                	slli	a5,a5,0x7
  return c;
}
    800018be:	00011517          	auipc	a0,0x11
    800018c2:	aea50513          	addi	a0,a0,-1302 # 800123a8 <cpus>
    800018c6:	953e                	add	a0,a0,a5
    800018c8:	6422                	ld	s0,8(sp)
    800018ca:	0141                	addi	sp,sp,16
    800018cc:	8082                	ret

00000000800018ce <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800018ce:	1101                	addi	sp,sp,-32
    800018d0:	ec06                	sd	ra,24(sp)
    800018d2:	e822                	sd	s0,16(sp)
    800018d4:	e426                	sd	s1,8(sp)
    800018d6:	1000                	addi	s0,sp,32
  push_off();
    800018d8:	ab6ff0ef          	jal	80000b8e <push_off>
    800018dc:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800018de:	2781                	sext.w	a5,a5
    800018e0:	079e                	slli	a5,a5,0x7
    800018e2:	00011717          	auipc	a4,0x11
    800018e6:	a9670713          	addi	a4,a4,-1386 # 80012378 <pid_lock>
    800018ea:	97ba                	add	a5,a5,a4
    800018ec:	7b84                	ld	s1,48(a5)
  pop_off();
    800018ee:	b24ff0ef          	jal	80000c12 <pop_off>
  return p;
}
    800018f2:	8526                	mv	a0,s1
    800018f4:	60e2                	ld	ra,24(sp)
    800018f6:	6442                	ld	s0,16(sp)
    800018f8:	64a2                	ld	s1,8(sp)
    800018fa:	6105                	addi	sp,sp,32
    800018fc:	8082                	ret

00000000800018fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800018fe:	7179                	addi	sp,sp,-48
    80001900:	f406                	sd	ra,40(sp)
    80001902:	f022                	sd	s0,32(sp)
    80001904:	ec26                	sd	s1,24(sp)
    80001906:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001908:	fc7ff0ef          	jal	800018ce <myproc>
    8000190c:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    8000190e:	b58ff0ef          	jal	80000c66 <release>

  if (first) {
    80001912:	00009797          	auipc	a5,0x9
    80001916:	90e7a783          	lw	a5,-1778(a5) # 8000a220 <first.1>
    8000191a:	cf8d                	beqz	a5,80001954 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    8000191c:	4505                	li	a0,1
    8000191e:	523010ef          	jal	80003640 <fsinit>

    first = 0;
    80001922:	00009797          	auipc	a5,0x9
    80001926:	8e07af23          	sw	zero,-1794(a5) # 8000a220 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    8000192a:	0330000f          	fence	rw,rw

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    8000192e:	00006517          	auipc	a0,0x6
    80001932:	85250513          	addi	a0,a0,-1966 # 80007180 <etext+0x180>
    80001936:	fca43823          	sd	a0,-48(s0)
    8000193a:	fc043c23          	sd	zero,-40(s0)
    8000193e:	fd040593          	addi	a1,s0,-48
    80001942:	609020ef          	jal	8000474a <kexec>
    80001946:	6cbc                	ld	a5,88(s1)
    80001948:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    8000194a:	6cbc                	ld	a5,88(s1)
    8000194c:	7bb8                	ld	a4,112(a5)
    8000194e:	57fd                	li	a5,-1
    80001950:	02f70d63          	beq	a4,a5,8000198a <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001954:	387000ef          	jal	800024da <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001958:	68a8                	ld	a0,80(s1)
    8000195a:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000195c:	04000737          	lui	a4,0x4000
    80001960:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80001962:	0732                	slli	a4,a4,0xc
    80001964:	00004797          	auipc	a5,0x4
    80001968:	73878793          	addi	a5,a5,1848 # 8000609c <userret>
    8000196c:	00004697          	auipc	a3,0x4
    80001970:	69468693          	addi	a3,a3,1684 # 80006000 <_trampoline>
    80001974:	8f95                	sub	a5,a5,a3
    80001976:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001978:	577d                	li	a4,-1
    8000197a:	177e                	slli	a4,a4,0x3f
    8000197c:	8d59                	or	a0,a0,a4
    8000197e:	9782                	jalr	a5
}
    80001980:	70a2                	ld	ra,40(sp)
    80001982:	7402                	ld	s0,32(sp)
    80001984:	64e2                	ld	s1,24(sp)
    80001986:	6145                	addi	sp,sp,48
    80001988:	8082                	ret
      panic("exec");
    8000198a:	00005517          	auipc	a0,0x5
    8000198e:	7fe50513          	addi	a0,a0,2046 # 80007188 <etext+0x188>
    80001992:	e4ffe0ef          	jal	800007e0 <panic>

0000000080001996 <allocpid>:
{
    80001996:	1101                	addi	sp,sp,-32
    80001998:	ec06                	sd	ra,24(sp)
    8000199a:	e822                	sd	s0,16(sp)
    8000199c:	e426                	sd	s1,8(sp)
    8000199e:	e04a                	sd	s2,0(sp)
    800019a0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019a2:	00011917          	auipc	s2,0x11
    800019a6:	9d690913          	addi	s2,s2,-1578 # 80012378 <pid_lock>
    800019aa:	854a                	mv	a0,s2
    800019ac:	a22ff0ef          	jal	80000bce <acquire>
  pid = nextpid;
    800019b0:	00009797          	auipc	a5,0x9
    800019b4:	87878793          	addi	a5,a5,-1928 # 8000a228 <nextpid>
    800019b8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019ba:	0014871b          	addiw	a4,s1,1
    800019be:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019c0:	854a                	mv	a0,s2
    800019c2:	aa4ff0ef          	jal	80000c66 <release>
}
    800019c6:	8526                	mv	a0,s1
    800019c8:	60e2                	ld	ra,24(sp)
    800019ca:	6442                	ld	s0,16(sp)
    800019cc:	64a2                	ld	s1,8(sp)
    800019ce:	6902                	ld	s2,0(sp)
    800019d0:	6105                	addi	sp,sp,32
    800019d2:	8082                	ret

00000000800019d4 <proc_pagetable>:
{
    800019d4:	1101                	addi	sp,sp,-32
    800019d6:	ec06                	sd	ra,24(sp)
    800019d8:	e822                	sd	s0,16(sp)
    800019da:	e426                	sd	s1,8(sp)
    800019dc:	e04a                	sd	s2,0(sp)
    800019de:	1000                	addi	s0,sp,32
    800019e0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019e2:	fb2ff0ef          	jal	80001194 <uvmcreate>
    800019e6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019e8:	cd05                	beqz	a0,80001a20 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019ea:	4729                	li	a4,10
    800019ec:	00004697          	auipc	a3,0x4
    800019f0:	61468693          	addi	a3,a3,1556 # 80006000 <_trampoline>
    800019f4:	6605                	lui	a2,0x1
    800019f6:	040005b7          	lui	a1,0x4000
    800019fa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800019fc:	05b2                	slli	a1,a1,0xc
    800019fe:	df0ff0ef          	jal	80000fee <mappages>
    80001a02:	02054663          	bltz	a0,80001a2e <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a06:	4719                	li	a4,6
    80001a08:	05893683          	ld	a3,88(s2)
    80001a0c:	6605                	lui	a2,0x1
    80001a0e:	020005b7          	lui	a1,0x2000
    80001a12:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a14:	05b6                	slli	a1,a1,0xd
    80001a16:	8526                	mv	a0,s1
    80001a18:	dd6ff0ef          	jal	80000fee <mappages>
    80001a1c:	00054f63          	bltz	a0,80001a3a <proc_pagetable+0x66>
}
    80001a20:	8526                	mv	a0,s1
    80001a22:	60e2                	ld	ra,24(sp)
    80001a24:	6442                	ld	s0,16(sp)
    80001a26:	64a2                	ld	s1,8(sp)
    80001a28:	6902                	ld	s2,0(sp)
    80001a2a:	6105                	addi	sp,sp,32
    80001a2c:	8082                	ret
    uvmfree(pagetable, 0);
    80001a2e:	4581                	li	a1,0
    80001a30:	8526                	mv	a0,s1
    80001a32:	95dff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001a36:	4481                	li	s1,0
    80001a38:	b7e5                	j	80001a20 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a3a:	4681                	li	a3,0
    80001a3c:	4605                	li	a2,1
    80001a3e:	040005b7          	lui	a1,0x4000
    80001a42:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a44:	05b2                	slli	a1,a1,0xc
    80001a46:	8526                	mv	a0,s1
    80001a48:	f72ff0ef          	jal	800011ba <uvmunmap>
    uvmfree(pagetable, 0);
    80001a4c:	4581                	li	a1,0
    80001a4e:	8526                	mv	a0,s1
    80001a50:	93fff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001a54:	4481                	li	s1,0
    80001a56:	b7e9                	j	80001a20 <proc_pagetable+0x4c>

0000000080001a58 <proc_freepagetable>:
{
    80001a58:	1101                	addi	sp,sp,-32
    80001a5a:	ec06                	sd	ra,24(sp)
    80001a5c:	e822                	sd	s0,16(sp)
    80001a5e:	e426                	sd	s1,8(sp)
    80001a60:	e04a                	sd	s2,0(sp)
    80001a62:	1000                	addi	s0,sp,32
    80001a64:	84aa                	mv	s1,a0
    80001a66:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a68:	4681                	li	a3,0
    80001a6a:	4605                	li	a2,1
    80001a6c:	040005b7          	lui	a1,0x4000
    80001a70:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a72:	05b2                	slli	a1,a1,0xc
    80001a74:	f46ff0ef          	jal	800011ba <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a78:	4681                	li	a3,0
    80001a7a:	4605                	li	a2,1
    80001a7c:	020005b7          	lui	a1,0x2000
    80001a80:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a82:	05b6                	slli	a1,a1,0xd
    80001a84:	8526                	mv	a0,s1
    80001a86:	f34ff0ef          	jal	800011ba <uvmunmap>
  uvmfree(pagetable, sz);
    80001a8a:	85ca                	mv	a1,s2
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	901ff0ef          	jal	8000138e <uvmfree>
}
    80001a92:	60e2                	ld	ra,24(sp)
    80001a94:	6442                	ld	s0,16(sp)
    80001a96:	64a2                	ld	s1,8(sp)
    80001a98:	6902                	ld	s2,0(sp)
    80001a9a:	6105                	addi	sp,sp,32
    80001a9c:	8082                	ret

0000000080001a9e <freeproc>:
{
    80001a9e:	1101                	addi	sp,sp,-32
    80001aa0:	ec06                	sd	ra,24(sp)
    80001aa2:	e822                	sd	s0,16(sp)
    80001aa4:	e426                	sd	s1,8(sp)
    80001aa6:	1000                	addi	s0,sp,32
    80001aa8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001aaa:	6d28                	ld	a0,88(a0)
    80001aac:	c119                	beqz	a0,80001ab2 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001aae:	f6ffe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80001ab2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ab6:	68a8                	ld	a0,80(s1)
    80001ab8:	c501                	beqz	a0,80001ac0 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001aba:	64ac                	ld	a1,72(s1)
    80001abc:	f9dff0ef          	jal	80001a58 <proc_freepagetable>
  p->pagetable = 0;
    80001ac0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ac4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ac8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001acc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ad0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ad4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ad8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001adc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ae0:	0004ac23          	sw	zero,24(s1)
}
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6105                	addi	sp,sp,32
    80001aec:	8082                	ret

0000000080001aee <allocproc>:
{
    80001aee:	1101                	addi	sp,sp,-32
    80001af0:	ec06                	sd	ra,24(sp)
    80001af2:	e822                	sd	s0,16(sp)
    80001af4:	e426                	sd	s1,8(sp)
    80001af6:	e04a                	sd	s2,0(sp)
    80001af8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001afa:	00011497          	auipc	s1,0x11
    80001afe:	cae48493          	addi	s1,s1,-850 # 800127a8 <proc>
    80001b02:	00017917          	auipc	s2,0x17
    80001b06:	8a690913          	addi	s2,s2,-1882 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	8c2ff0ef          	jal	80000bce <acquire>
    if(p->state == UNUSED) {
    80001b10:	4c9c                	lw	a5,24(s1)
    80001b12:	cb91                	beqz	a5,80001b26 <allocproc+0x38>
      release(&p->lock);
    80001b14:	8526                	mv	a0,s1
    80001b16:	950ff0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b1a:	17048493          	addi	s1,s1,368
    80001b1e:	ff2496e3          	bne	s1,s2,80001b0a <allocproc+0x1c>
  return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	a099                	j	80001b6a <allocproc+0x7c>
  p->pid = allocpid();
    80001b26:	e71ff0ef          	jal	80001996 <allocpid>
    80001b2a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b2c:	4785                	li	a5,1
    80001b2e:	cc9c                	sw	a5,24(s1)
  p->priority = 1;
    80001b30:	16f4a423          	sw	a5,360(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001b34:	fcbfe0ef          	jal	80000afe <kalloc>
    80001b38:	892a                	mv	s2,a0
    80001b3a:	eca8                	sd	a0,88(s1)
    80001b3c:	cd15                	beqz	a0,80001b78 <allocproc+0x8a>
  p->pagetable = proc_pagetable(p);
    80001b3e:	8526                	mv	a0,s1
    80001b40:	e95ff0ef          	jal	800019d4 <proc_pagetable>
    80001b44:	892a                	mv	s2,a0
    80001b46:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001b48:	c121                	beqz	a0,80001b88 <allocproc+0x9a>
  memset(&p->context, 0, sizeof(p->context));
    80001b4a:	07000613          	li	a2,112
    80001b4e:	4581                	li	a1,0
    80001b50:	06048513          	addi	a0,s1,96
    80001b54:	94eff0ef          	jal	80000ca2 <memset>
  p->context.ra = (uint64)forkret;
    80001b58:	00000797          	auipc	a5,0x0
    80001b5c:	da678793          	addi	a5,a5,-602 # 800018fe <forkret>
    80001b60:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001b62:	60bc                	ld	a5,64(s1)
    80001b64:	6705                	lui	a4,0x1
    80001b66:	97ba                	add	a5,a5,a4
    80001b68:	f4bc                	sd	a5,104(s1)
}
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret
    freeproc(p);
    80001b78:	8526                	mv	a0,s1
    80001b7a:	f25ff0ef          	jal	80001a9e <freeproc>
    release(&p->lock);
    80001b7e:	8526                	mv	a0,s1
    80001b80:	8e6ff0ef          	jal	80000c66 <release>
    return 0;
    80001b84:	84ca                	mv	s1,s2
    80001b86:	b7d5                	j	80001b6a <allocproc+0x7c>
    freeproc(p);
    80001b88:	8526                	mv	a0,s1
    80001b8a:	f15ff0ef          	jal	80001a9e <freeproc>
    release(&p->lock);
    80001b8e:	8526                	mv	a0,s1
    80001b90:	8d6ff0ef          	jal	80000c66 <release>
    return 0;
    80001b94:	84ca                	mv	s1,s2
    80001b96:	bfd1                	j	80001b6a <allocproc+0x7c>

0000000080001b98 <userinit>:
{
    80001b98:	1101                	addi	sp,sp,-32
    80001b9a:	ec06                	sd	ra,24(sp)
    80001b9c:	e822                	sd	s0,16(sp)
    80001b9e:	e426                	sd	s1,8(sp)
    80001ba0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ba2:	f4dff0ef          	jal	80001aee <allocproc>
    80001ba6:	84aa                	mv	s1,a0
  initproc = p;
    80001ba8:	00008797          	auipc	a5,0x8
    80001bac:	6ca7b423          	sd	a0,1736(a5) # 8000a270 <initproc>
  p->cwd = namei("/");
    80001bb0:	00005517          	auipc	a0,0x5
    80001bb4:	5e050513          	addi	a0,a0,1504 # 80007190 <etext+0x190>
    80001bb8:	7ab010ef          	jal	80003b62 <namei>
    80001bbc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001bc0:	478d                	li	a5,3
    80001bc2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	8a0ff0ef          	jal	80000c66 <release>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6105                	addi	sp,sp,32
    80001bd2:	8082                	ret

0000000080001bd4 <growproc>:
{
    80001bd4:	1101                	addi	sp,sp,-32
    80001bd6:	ec06                	sd	ra,24(sp)
    80001bd8:	e822                	sd	s0,16(sp)
    80001bda:	e426                	sd	s1,8(sp)
    80001bdc:	e04a                	sd	s2,0(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001be2:	cedff0ef          	jal	800018ce <myproc>
    80001be6:	892a                	mv	s2,a0
  sz = p->sz;
    80001be8:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001bea:	02905963          	blez	s1,80001c1c <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001bee:	00b48633          	add	a2,s1,a1
    80001bf2:	020007b7          	lui	a5,0x2000
    80001bf6:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001bf8:	07b6                	slli	a5,a5,0xd
    80001bfa:	02c7ea63          	bltu	a5,a2,80001c2e <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001bfe:	4691                	li	a3,4
    80001c00:	6928                	ld	a0,80(a0)
    80001c02:	e86ff0ef          	jal	80001288 <uvmalloc>
    80001c06:	85aa                	mv	a1,a0
    80001c08:	c50d                	beqz	a0,80001c32 <growproc+0x5e>
  p->sz = sz;
    80001c0a:	04b93423          	sd	a1,72(s2)
  return 0;
    80001c0e:	4501                	li	a0,0
}
    80001c10:	60e2                	ld	ra,24(sp)
    80001c12:	6442                	ld	s0,16(sp)
    80001c14:	64a2                	ld	s1,8(sp)
    80001c16:	6902                	ld	s2,0(sp)
    80001c18:	6105                	addi	sp,sp,32
    80001c1a:	8082                	ret
  } else if(n < 0){
    80001c1c:	fe04d7e3          	bgez	s1,80001c0a <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c20:	00b48633          	add	a2,s1,a1
    80001c24:	6928                	ld	a0,80(a0)
    80001c26:	e1eff0ef          	jal	80001244 <uvmdealloc>
    80001c2a:	85aa                	mv	a1,a0
    80001c2c:	bff9                	j	80001c0a <growproc+0x36>
      return -1;
    80001c2e:	557d                	li	a0,-1
    80001c30:	b7c5                	j	80001c10 <growproc+0x3c>
      return -1;
    80001c32:	557d                	li	a0,-1
    80001c34:	bff1                	j	80001c10 <growproc+0x3c>

0000000080001c36 <kfork>:
{
    80001c36:	7139                	addi	sp,sp,-64
    80001c38:	fc06                	sd	ra,56(sp)
    80001c3a:	f822                	sd	s0,48(sp)
    80001c3c:	f04a                	sd	s2,32(sp)
    80001c3e:	e456                	sd	s5,8(sp)
    80001c40:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c42:	c8dff0ef          	jal	800018ce <myproc>
    80001c46:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001c48:	ea7ff0ef          	jal	80001aee <allocproc>
    80001c4c:	0e050a63          	beqz	a0,80001d40 <kfork+0x10a>
    80001c50:	e852                	sd	s4,16(sp)
    80001c52:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001c54:	048ab603          	ld	a2,72(s5)
    80001c58:	692c                	ld	a1,80(a0)
    80001c5a:	050ab503          	ld	a0,80(s5)
    80001c5e:	f62ff0ef          	jal	800013c0 <uvmcopy>
    80001c62:	04054a63          	bltz	a0,80001cb6 <kfork+0x80>
    80001c66:	f426                	sd	s1,40(sp)
    80001c68:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001c6a:	048ab783          	ld	a5,72(s5)
    80001c6e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001c72:	058ab683          	ld	a3,88(s5)
    80001c76:	87b6                	mv	a5,a3
    80001c78:	058a3703          	ld	a4,88(s4)
    80001c7c:	12068693          	addi	a3,a3,288
    80001c80:	0007b803          	ld	a6,0(a5)
    80001c84:	6788                	ld	a0,8(a5)
    80001c86:	6b8c                	ld	a1,16(a5)
    80001c88:	6f90                	ld	a2,24(a5)
    80001c8a:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001c8e:	e708                	sd	a0,8(a4)
    80001c90:	eb0c                	sd	a1,16(a4)
    80001c92:	ef10                	sd	a2,24(a4)
    80001c94:	02078793          	addi	a5,a5,32
    80001c98:	02070713          	addi	a4,a4,32
    80001c9c:	fed792e3          	bne	a5,a3,80001c80 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001ca0:	058a3783          	ld	a5,88(s4)
    80001ca4:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ca8:	0d0a8493          	addi	s1,s5,208
    80001cac:	0d0a0913          	addi	s2,s4,208
    80001cb0:	150a8993          	addi	s3,s5,336
    80001cb4:	a831                	j	80001cd0 <kfork+0x9a>
    freeproc(np);
    80001cb6:	8552                	mv	a0,s4
    80001cb8:	de7ff0ef          	jal	80001a9e <freeproc>
    release(&np->lock);
    80001cbc:	8552                	mv	a0,s4
    80001cbe:	fa9fe0ef          	jal	80000c66 <release>
    return -1;
    80001cc2:	597d                	li	s2,-1
    80001cc4:	6a42                	ld	s4,16(sp)
    80001cc6:	a0b5                	j	80001d32 <kfork+0xfc>
  for(i = 0; i < NOFILE; i++)
    80001cc8:	04a1                	addi	s1,s1,8
    80001cca:	0921                	addi	s2,s2,8
    80001ccc:	01348963          	beq	s1,s3,80001cde <kfork+0xa8>
    if(p->ofile[i])
    80001cd0:	6088                	ld	a0,0(s1)
    80001cd2:	d97d                	beqz	a0,80001cc8 <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001cd4:	428020ef          	jal	800040fc <filedup>
    80001cd8:	00a93023          	sd	a0,0(s2)
    80001cdc:	b7f5                	j	80001cc8 <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001cde:	150ab503          	ld	a0,336(s5)
    80001ce2:	634010ef          	jal	80003316 <idup>
    80001ce6:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001cea:	4641                	li	a2,16
    80001cec:	158a8593          	addi	a1,s5,344
    80001cf0:	158a0513          	addi	a0,s4,344
    80001cf4:	8ecff0ef          	jal	80000de0 <safestrcpy>
  pid = np->pid;
    80001cf8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001cfc:	8552                	mv	a0,s4
    80001cfe:	f69fe0ef          	jal	80000c66 <release>
  acquire(&wait_lock);
    80001d02:	00010497          	auipc	s1,0x10
    80001d06:	68e48493          	addi	s1,s1,1678 # 80012390 <wait_lock>
    80001d0a:	8526                	mv	a0,s1
    80001d0c:	ec3fe0ef          	jal	80000bce <acquire>
  np->parent = p;
    80001d10:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001d14:	8526                	mv	a0,s1
    80001d16:	f51fe0ef          	jal	80000c66 <release>
  acquire(&np->lock);
    80001d1a:	8552                	mv	a0,s4
    80001d1c:	eb3fe0ef          	jal	80000bce <acquire>
  np->state = RUNNABLE;
    80001d20:	478d                	li	a5,3
    80001d22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d26:	8552                	mv	a0,s4
    80001d28:	f3ffe0ef          	jal	80000c66 <release>
  return pid;
    80001d2c:	74a2                	ld	s1,40(sp)
    80001d2e:	69e2                	ld	s3,24(sp)
    80001d30:	6a42                	ld	s4,16(sp)
}
    80001d32:	854a                	mv	a0,s2
    80001d34:	70e2                	ld	ra,56(sp)
    80001d36:	7442                	ld	s0,48(sp)
    80001d38:	7902                	ld	s2,32(sp)
    80001d3a:	6aa2                	ld	s5,8(sp)
    80001d3c:	6121                	addi	sp,sp,64
    80001d3e:	8082                	ret
    return -1;
    80001d40:	597d                	li	s2,-1
    80001d42:	bfc5                	j	80001d32 <kfork+0xfc>

0000000080001d44 <scheduler>:
{
    80001d44:	7119                	addi	sp,sp,-128
    80001d46:	fc86                	sd	ra,120(sp)
    80001d48:	f8a2                	sd	s0,112(sp)
    80001d4a:	f4a6                	sd	s1,104(sp)
    80001d4c:	f0ca                	sd	s2,96(sp)
    80001d4e:	ecce                	sd	s3,88(sp)
    80001d50:	e8d2                	sd	s4,80(sp)
    80001d52:	e4d6                	sd	s5,72(sp)
    80001d54:	e0da                	sd	s6,64(sp)
    80001d56:	fc5e                	sd	s7,56(sp)
    80001d58:	f862                	sd	s8,48(sp)
    80001d5a:	f466                	sd	s9,40(sp)
    80001d5c:	f06a                	sd	s10,32(sp)
    80001d5e:	ec6e                	sd	s11,24(sp)
    80001d60:	0100                	addi	s0,sp,128
    80001d62:	8792                	mv	a5,tp
  int id = r_tp();
    80001d64:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d66:	00779693          	slli	a3,a5,0x7
    80001d6a:	00010717          	auipc	a4,0x10
    80001d6e:	60e70713          	addi	a4,a4,1550 # 80012378 <pid_lock>
    80001d72:	9736                	add	a4,a4,a3
    80001d74:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &best->context);
    80001d78:	00010717          	auipc	a4,0x10
    80001d7c:	63870713          	addi	a4,a4,1592 # 800123b0 <cpus+0x8>
    80001d80:	9736                	add	a4,a4,a3
    80001d82:	f8e43423          	sd	a4,-120(s0)
    int best_prio = -1; 
    80001d86:	5cfd                	li	s9,-1
    struct proc *best = 0;
    80001d88:	4d01                	li	s10,0
        if(sched_mode == 0 && found == 0){
    80001d8a:	00008b97          	auipc	s7,0x8
    80001d8e:	49ab8b93          	addi	s7,s7,1178 # 8000a224 <sched_mode>
        c->proc = best;
    80001d92:	00010d97          	auipc	s11,0x10
    80001d96:	5e6d8d93          	addi	s11,s11,1510 # 80012378 <pid_lock>
    80001d9a:	9db6                	add	s11,s11,a3
    80001d9c:	a881                	j	80001dec <scheduler+0xa8>
            best_prio = p->priority;
    80001d9e:	1684aa83          	lw	s5,360(s1)
            best = p;
    80001da2:	8c26                	mv	s8,s1
        found = 1;
    80001da4:	8a5a                	mv	s4,s6
    80001da6:	a019                	j	80001dac <scheduler+0x68>
          best = p;                // Normal Scheduler
    80001da8:	8c26                	mv	s8,s1
        found = 1;
    80001daa:	8a5a                	mv	s4,s6
      release(&p->lock);
    80001dac:	8526                	mv	a0,s1
    80001dae:	eb9fe0ef          	jal	80000c66 <release>
    for(p = proc; p < &proc[NPROC]; p++){
    80001db2:	17048493          	addi	s1,s1,368
    80001db6:	03248763          	beq	s1,s2,80001de4 <scheduler+0xa0>
      acquire(&p->lock);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	e13fe0ef          	jal	80000bce <acquire>
      if(p->state == RUNNABLE){
    80001dc0:	4c9c                	lw	a5,24(s1)
    80001dc2:	ff3795e3          	bne	a5,s3,80001dac <scheduler+0x68>
        if(sched_mode == 0 && found == 0){
    80001dc6:	000ba783          	lw	a5,0(s7)
    80001dca:	00fa67b3          	or	a5,s4,a5
    80001dce:	dfe9                	beqz	a5,80001da8 <scheduler+0x64>
          if(best_prio == -1){
    80001dd0:	fd9a87e3          	beq	s5,s9,80001d9e <scheduler+0x5a>
          else if (p->priority < best_prio){
    80001dd4:	1684a783          	lw	a5,360(s1)
        found = 1;
    80001dd8:	8a5a                	mv	s4,s6
          else if (p->priority < best_prio){
    80001dda:	fd57d9e3          	bge	a5,s5,80001dac <scheduler+0x68>
            best_prio = p->priority;
    80001dde:	8abe                	mv	s5,a5
            best = p;              // Prio Based Scheduler
    80001de0:	8c26                	mv	s8,s1
    80001de2:	b7e9                	j	80001dac <scheduler+0x68>
    if(found == 0){
    80001de4:	020a1d63          	bnez	s4,80001e1e <scheduler+0xda>
      asm volatile("wfi");
    80001de8:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001dec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001df0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001df4:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001df8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001dfc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001dfe:	10079073          	csrw	sstatus,a5
    int best_prio = -1; 
    80001e02:	8ae6                	mv	s5,s9
    struct proc *best = 0;
    80001e04:	8c6a                	mv	s8,s10
    int found = 0;
    80001e06:	8a6a                	mv	s4,s10
    for(p = proc; p < &proc[NPROC]; p++){
    80001e08:	00011497          	auipc	s1,0x11
    80001e0c:	9a048493          	addi	s1,s1,-1632 # 800127a8 <proc>
      if(p->state == RUNNABLE){
    80001e10:	498d                	li	s3,3
        found = 1;
    80001e12:	4b05                	li	s6,1
    for(p = proc; p < &proc[NPROC]; p++){
    80001e14:	00016917          	auipc	s2,0x16
    80001e18:	59490913          	addi	s2,s2,1428 # 800183a8 <tickslock>
    80001e1c:	bf79                	j	80001dba <scheduler+0x76>
      acquire(&best->lock);
    80001e1e:	84e2                	mv	s1,s8
    80001e20:	8562                	mv	a0,s8
    80001e22:	dadfe0ef          	jal	80000bce <acquire>
      if(best->state == RUNNABLE) {
    80001e26:	018c2703          	lw	a4,24(s8) # fffffffffffff018 <end+0xffffffff7ffdb890>
    80001e2a:	478d                	li	a5,3
    80001e2c:	00f70663          	beq	a4,a5,80001e38 <scheduler+0xf4>
      release(&best->lock);
    80001e30:	8526                	mv	a0,s1
    80001e32:	e35fe0ef          	jal	80000c66 <release>
    80001e36:	bf5d                	j	80001dec <scheduler+0xa8>
        best->state = RUNNING;
    80001e38:	4791                	li	a5,4
    80001e3a:	00fc2c23          	sw	a5,24(s8)
        c->proc = best;
    80001e3e:	038db823          	sd	s8,48(s11)
        swtch(&c->context, &best->context);
    80001e42:	060c0593          	addi	a1,s8,96
    80001e46:	f8843503          	ld	a0,-120(s0)
    80001e4a:	5ea000ef          	jal	80002434 <swtch>
        c->proc = 0;
    80001e4e:	020db823          	sd	zero,48(s11)
    80001e52:	bff9                	j	80001e30 <scheduler+0xec>

0000000080001e54 <sched>:
{
    80001e54:	7179                	addi	sp,sp,-48
    80001e56:	f406                	sd	ra,40(sp)
    80001e58:	f022                	sd	s0,32(sp)
    80001e5a:	ec26                	sd	s1,24(sp)
    80001e5c:	e84a                	sd	s2,16(sp)
    80001e5e:	e44e                	sd	s3,8(sp)
    80001e60:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e62:	a6dff0ef          	jal	800018ce <myproc>
    80001e66:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001e68:	cfdfe0ef          	jal	80000b64 <holding>
    80001e6c:	c92d                	beqz	a0,80001ede <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e6e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001e70:	2781                	sext.w	a5,a5
    80001e72:	079e                	slli	a5,a5,0x7
    80001e74:	00010717          	auipc	a4,0x10
    80001e78:	50470713          	addi	a4,a4,1284 # 80012378 <pid_lock>
    80001e7c:	97ba                	add	a5,a5,a4
    80001e7e:	0a87a703          	lw	a4,168(a5)
    80001e82:	4785                	li	a5,1
    80001e84:	06f71363          	bne	a4,a5,80001eea <sched+0x96>
  if(p->state == RUNNING)
    80001e88:	4c98                	lw	a4,24(s1)
    80001e8a:	4791                	li	a5,4
    80001e8c:	06f70563          	beq	a4,a5,80001ef6 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e90:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e94:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e96:	e7b5                	bnez	a5,80001f02 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e98:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e9a:	00010917          	auipc	s2,0x10
    80001e9e:	4de90913          	addi	s2,s2,1246 # 80012378 <pid_lock>
    80001ea2:	2781                	sext.w	a5,a5
    80001ea4:	079e                	slli	a5,a5,0x7
    80001ea6:	97ca                	add	a5,a5,s2
    80001ea8:	0ac7a983          	lw	s3,172(a5)
    80001eac:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001eae:	2781                	sext.w	a5,a5
    80001eb0:	079e                	slli	a5,a5,0x7
    80001eb2:	00010597          	auipc	a1,0x10
    80001eb6:	4fe58593          	addi	a1,a1,1278 # 800123b0 <cpus+0x8>
    80001eba:	95be                	add	a1,a1,a5
    80001ebc:	06048513          	addi	a0,s1,96
    80001ec0:	574000ef          	jal	80002434 <swtch>
    80001ec4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ec6:	2781                	sext.w	a5,a5
    80001ec8:	079e                	slli	a5,a5,0x7
    80001eca:	993e                	add	s2,s2,a5
    80001ecc:	0b392623          	sw	s3,172(s2)
}
    80001ed0:	70a2                	ld	ra,40(sp)
    80001ed2:	7402                	ld	s0,32(sp)
    80001ed4:	64e2                	ld	s1,24(sp)
    80001ed6:	6942                	ld	s2,16(sp)
    80001ed8:	69a2                	ld	s3,8(sp)
    80001eda:	6145                	addi	sp,sp,48
    80001edc:	8082                	ret
    panic("sched p->lock");
    80001ede:	00005517          	auipc	a0,0x5
    80001ee2:	2ba50513          	addi	a0,a0,698 # 80007198 <etext+0x198>
    80001ee6:	8fbfe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    80001eea:	00005517          	auipc	a0,0x5
    80001eee:	2be50513          	addi	a0,a0,702 # 800071a8 <etext+0x1a8>
    80001ef2:	8effe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    80001ef6:	00005517          	auipc	a0,0x5
    80001efa:	2c250513          	addi	a0,a0,706 # 800071b8 <etext+0x1b8>
    80001efe:	8e3fe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80001f02:	00005517          	auipc	a0,0x5
    80001f06:	2c650513          	addi	a0,a0,710 # 800071c8 <etext+0x1c8>
    80001f0a:	8d7fe0ef          	jal	800007e0 <panic>

0000000080001f0e <yield>:
{
    80001f0e:	1101                	addi	sp,sp,-32
    80001f10:	ec06                	sd	ra,24(sp)
    80001f12:	e822                	sd	s0,16(sp)
    80001f14:	e426                	sd	s1,8(sp)
    80001f16:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001f18:	9b7ff0ef          	jal	800018ce <myproc>
    80001f1c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001f1e:	cb1fe0ef          	jal	80000bce <acquire>
  p->state = RUNNABLE;
    80001f22:	478d                	li	a5,3
    80001f24:	cc9c                	sw	a5,24(s1)
  sched();
    80001f26:	f2fff0ef          	jal	80001e54 <sched>
  release(&p->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	d3bfe0ef          	jal	80000c66 <release>
}
    80001f30:	60e2                	ld	ra,24(sp)
    80001f32:	6442                	ld	s0,16(sp)
    80001f34:	64a2                	ld	s1,8(sp)
    80001f36:	6105                	addi	sp,sp,32
    80001f38:	8082                	ret

0000000080001f3a <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001f3a:	7179                	addi	sp,sp,-48
    80001f3c:	f406                	sd	ra,40(sp)
    80001f3e:	f022                	sd	s0,32(sp)
    80001f40:	ec26                	sd	s1,24(sp)
    80001f42:	e84a                	sd	s2,16(sp)
    80001f44:	e44e                	sd	s3,8(sp)
    80001f46:	1800                	addi	s0,sp,48
    80001f48:	89aa                	mv	s3,a0
    80001f4a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001f4c:	983ff0ef          	jal	800018ce <myproc>
    80001f50:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001f52:	c7dfe0ef          	jal	80000bce <acquire>
  release(lk);
    80001f56:	854a                	mv	a0,s2
    80001f58:	d0ffe0ef          	jal	80000c66 <release>

  // Go to sleep.
  p->chan = chan;
    80001f5c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001f60:	4789                	li	a5,2
    80001f62:	cc9c                	sw	a5,24(s1)

  sched();
    80001f64:	ef1ff0ef          	jal	80001e54 <sched>

  // Tidy up.
  p->chan = 0;
    80001f68:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	cf9fe0ef          	jal	80000c66 <release>
  acquire(lk);
    80001f72:	854a                	mv	a0,s2
    80001f74:	c5bfe0ef          	jal	80000bce <acquire>
}
    80001f78:	70a2                	ld	ra,40(sp)
    80001f7a:	7402                	ld	s0,32(sp)
    80001f7c:	64e2                	ld	s1,24(sp)
    80001f7e:	6942                	ld	s2,16(sp)
    80001f80:	69a2                	ld	s3,8(sp)
    80001f82:	6145                	addi	sp,sp,48
    80001f84:	8082                	ret

0000000080001f86 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001f86:	7139                	addi	sp,sp,-64
    80001f88:	fc06                	sd	ra,56(sp)
    80001f8a:	f822                	sd	s0,48(sp)
    80001f8c:	f426                	sd	s1,40(sp)
    80001f8e:	f04a                	sd	s2,32(sp)
    80001f90:	ec4e                	sd	s3,24(sp)
    80001f92:	e852                	sd	s4,16(sp)
    80001f94:	e456                	sd	s5,8(sp)
    80001f96:	0080                	addi	s0,sp,64
    80001f98:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001f9a:	00011497          	auipc	s1,0x11
    80001f9e:	80e48493          	addi	s1,s1,-2034 # 800127a8 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001fa2:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001fa4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fa6:	00016917          	auipc	s2,0x16
    80001faa:	40290913          	addi	s2,s2,1026 # 800183a8 <tickslock>
    80001fae:	a801                	j	80001fbe <wakeup+0x38>
      }
      release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	cb5fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fb6:	17048493          	addi	s1,s1,368
    80001fba:	03248263          	beq	s1,s2,80001fde <wakeup+0x58>
    if(p != myproc()){
    80001fbe:	911ff0ef          	jal	800018ce <myproc>
    80001fc2:	fea48ae3          	beq	s1,a0,80001fb6 <wakeup+0x30>
      acquire(&p->lock);
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	c07fe0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001fcc:	4c9c                	lw	a5,24(s1)
    80001fce:	ff3791e3          	bne	a5,s3,80001fb0 <wakeup+0x2a>
    80001fd2:	709c                	ld	a5,32(s1)
    80001fd4:	fd479ee3          	bne	a5,s4,80001fb0 <wakeup+0x2a>
        p->state = RUNNABLE;
    80001fd8:	0154ac23          	sw	s5,24(s1)
    80001fdc:	bfd1                	j	80001fb0 <wakeup+0x2a>
    }
  }
}
    80001fde:	70e2                	ld	ra,56(sp)
    80001fe0:	7442                	ld	s0,48(sp)
    80001fe2:	74a2                	ld	s1,40(sp)
    80001fe4:	7902                	ld	s2,32(sp)
    80001fe6:	69e2                	ld	s3,24(sp)
    80001fe8:	6a42                	ld	s4,16(sp)
    80001fea:	6aa2                	ld	s5,8(sp)
    80001fec:	6121                	addi	sp,sp,64
    80001fee:	8082                	ret

0000000080001ff0 <reparent>:
{
    80001ff0:	7179                	addi	sp,sp,-48
    80001ff2:	f406                	sd	ra,40(sp)
    80001ff4:	f022                	sd	s0,32(sp)
    80001ff6:	ec26                	sd	s1,24(sp)
    80001ff8:	e84a                	sd	s2,16(sp)
    80001ffa:	e44e                	sd	s3,8(sp)
    80001ffc:	e052                	sd	s4,0(sp)
    80001ffe:	1800                	addi	s0,sp,48
    80002000:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002002:	00010497          	auipc	s1,0x10
    80002006:	7a648493          	addi	s1,s1,1958 # 800127a8 <proc>
      pp->parent = initproc;
    8000200a:	00008a17          	auipc	s4,0x8
    8000200e:	266a0a13          	addi	s4,s4,614 # 8000a270 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002012:	00016997          	auipc	s3,0x16
    80002016:	39698993          	addi	s3,s3,918 # 800183a8 <tickslock>
    8000201a:	a029                	j	80002024 <reparent+0x34>
    8000201c:	17048493          	addi	s1,s1,368
    80002020:	01348b63          	beq	s1,s3,80002036 <reparent+0x46>
    if(pp->parent == p){
    80002024:	7c9c                	ld	a5,56(s1)
    80002026:	ff279be3          	bne	a5,s2,8000201c <reparent+0x2c>
      pp->parent = initproc;
    8000202a:	000a3503          	ld	a0,0(s4)
    8000202e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002030:	f57ff0ef          	jal	80001f86 <wakeup>
    80002034:	b7e5                	j	8000201c <reparent+0x2c>
}
    80002036:	70a2                	ld	ra,40(sp)
    80002038:	7402                	ld	s0,32(sp)
    8000203a:	64e2                	ld	s1,24(sp)
    8000203c:	6942                	ld	s2,16(sp)
    8000203e:	69a2                	ld	s3,8(sp)
    80002040:	6a02                	ld	s4,0(sp)
    80002042:	6145                	addi	sp,sp,48
    80002044:	8082                	ret

0000000080002046 <kexit>:
{
    80002046:	7179                	addi	sp,sp,-48
    80002048:	f406                	sd	ra,40(sp)
    8000204a:	f022                	sd	s0,32(sp)
    8000204c:	ec26                	sd	s1,24(sp)
    8000204e:	e84a                	sd	s2,16(sp)
    80002050:	e44e                	sd	s3,8(sp)
    80002052:	e052                	sd	s4,0(sp)
    80002054:	1800                	addi	s0,sp,48
    80002056:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002058:	877ff0ef          	jal	800018ce <myproc>
    8000205c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000205e:	00008797          	auipc	a5,0x8
    80002062:	2127b783          	ld	a5,530(a5) # 8000a270 <initproc>
    80002066:	0d050493          	addi	s1,a0,208
    8000206a:	15050913          	addi	s2,a0,336
    8000206e:	00a79f63          	bne	a5,a0,8000208c <kexit+0x46>
    panic("init exiting");
    80002072:	00005517          	auipc	a0,0x5
    80002076:	16e50513          	addi	a0,a0,366 # 800071e0 <etext+0x1e0>
    8000207a:	f66fe0ef          	jal	800007e0 <panic>
      fileclose(f);
    8000207e:	0c4020ef          	jal	80004142 <fileclose>
      p->ofile[fd] = 0;
    80002082:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002086:	04a1                	addi	s1,s1,8
    80002088:	01248563          	beq	s1,s2,80002092 <kexit+0x4c>
    if(p->ofile[fd]){
    8000208c:	6088                	ld	a0,0(s1)
    8000208e:	f965                	bnez	a0,8000207e <kexit+0x38>
    80002090:	bfdd                	j	80002086 <kexit+0x40>
  begin_op();
    80002092:	4a5010ef          	jal	80003d36 <begin_op>
  iput(p->cwd);
    80002096:	1509b503          	ld	a0,336(s3)
    8000209a:	434010ef          	jal	800034ce <iput>
  end_op();
    8000209e:	503010ef          	jal	80003da0 <end_op>
  p->cwd = 0;
    800020a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800020a6:	00010497          	auipc	s1,0x10
    800020aa:	2ea48493          	addi	s1,s1,746 # 80012390 <wait_lock>
    800020ae:	8526                	mv	a0,s1
    800020b0:	b1ffe0ef          	jal	80000bce <acquire>
  reparent(p);
    800020b4:	854e                	mv	a0,s3
    800020b6:	f3bff0ef          	jal	80001ff0 <reparent>
  wakeup(p->parent);
    800020ba:	0389b503          	ld	a0,56(s3)
    800020be:	ec9ff0ef          	jal	80001f86 <wakeup>
  acquire(&p->lock);
    800020c2:	854e                	mv	a0,s3
    800020c4:	b0bfe0ef          	jal	80000bce <acquire>
  p->xstate = status;
    800020c8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800020cc:	4795                	li	a5,5
    800020ce:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800020d2:	8526                	mv	a0,s1
    800020d4:	b93fe0ef          	jal	80000c66 <release>
  sched();
    800020d8:	d7dff0ef          	jal	80001e54 <sched>
  panic("zombie exit");
    800020dc:	00005517          	auipc	a0,0x5
    800020e0:	11450513          	addi	a0,a0,276 # 800071f0 <etext+0x1f0>
    800020e4:	efcfe0ef          	jal	800007e0 <panic>

00000000800020e8 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    800020e8:	7179                	addi	sp,sp,-48
    800020ea:	f406                	sd	ra,40(sp)
    800020ec:	f022                	sd	s0,32(sp)
    800020ee:	ec26                	sd	s1,24(sp)
    800020f0:	e84a                	sd	s2,16(sp)
    800020f2:	e44e                	sd	s3,8(sp)
    800020f4:	1800                	addi	s0,sp,48
    800020f6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800020f8:	00010497          	auipc	s1,0x10
    800020fc:	6b048493          	addi	s1,s1,1712 # 800127a8 <proc>
    80002100:	00016997          	auipc	s3,0x16
    80002104:	2a898993          	addi	s3,s3,680 # 800183a8 <tickslock>
    acquire(&p->lock);
    80002108:	8526                	mv	a0,s1
    8000210a:	ac5fe0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    8000210e:	589c                	lw	a5,48(s1)
    80002110:	01278b63          	beq	a5,s2,80002126 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002114:	8526                	mv	a0,s1
    80002116:	b51fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000211a:	17048493          	addi	s1,s1,368
    8000211e:	ff3495e3          	bne	s1,s3,80002108 <kkill+0x20>
  }
  return -1;
    80002122:	557d                	li	a0,-1
    80002124:	a819                	j	8000213a <kkill+0x52>
      p->killed = 1;
    80002126:	4785                	li	a5,1
    80002128:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000212a:	4c98                	lw	a4,24(s1)
    8000212c:	4789                	li	a5,2
    8000212e:	00f70d63          	beq	a4,a5,80002148 <kkill+0x60>
      release(&p->lock);
    80002132:	8526                	mv	a0,s1
    80002134:	b33fe0ef          	jal	80000c66 <release>
      return 0;
    80002138:	4501                	li	a0,0
}
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6145                	addi	sp,sp,48
    80002146:	8082                	ret
        p->state = RUNNABLE;
    80002148:	478d                	li	a5,3
    8000214a:	cc9c                	sw	a5,24(s1)
    8000214c:	b7dd                	j	80002132 <kkill+0x4a>

000000008000214e <setkilled>:

void
setkilled(struct proc *p)
{
    8000214e:	1101                	addi	sp,sp,-32
    80002150:	ec06                	sd	ra,24(sp)
    80002152:	e822                	sd	s0,16(sp)
    80002154:	e426                	sd	s1,8(sp)
    80002156:	1000                	addi	s0,sp,32
    80002158:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000215a:	a75fe0ef          	jal	80000bce <acquire>
  p->killed = 1;
    8000215e:	4785                	li	a5,1
    80002160:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	b03fe0ef          	jal	80000c66 <release>
}
    80002168:	60e2                	ld	ra,24(sp)
    8000216a:	6442                	ld	s0,16(sp)
    8000216c:	64a2                	ld	s1,8(sp)
    8000216e:	6105                	addi	sp,sp,32
    80002170:	8082                	ret

0000000080002172 <killed>:

int
killed(struct proc *p)
{
    80002172:	1101                	addi	sp,sp,-32
    80002174:	ec06                	sd	ra,24(sp)
    80002176:	e822                	sd	s0,16(sp)
    80002178:	e426                	sd	s1,8(sp)
    8000217a:	e04a                	sd	s2,0(sp)
    8000217c:	1000                	addi	s0,sp,32
    8000217e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002180:	a4ffe0ef          	jal	80000bce <acquire>
  k = p->killed;
    80002184:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	addfe0ef          	jal	80000c66 <release>
  return k;
}
    8000218e:	854a                	mv	a0,s2
    80002190:	60e2                	ld	ra,24(sp)
    80002192:	6442                	ld	s0,16(sp)
    80002194:	64a2                	ld	s1,8(sp)
    80002196:	6902                	ld	s2,0(sp)
    80002198:	6105                	addi	sp,sp,32
    8000219a:	8082                	ret

000000008000219c <kwait>:
{
    8000219c:	715d                	addi	sp,sp,-80
    8000219e:	e486                	sd	ra,72(sp)
    800021a0:	e0a2                	sd	s0,64(sp)
    800021a2:	fc26                	sd	s1,56(sp)
    800021a4:	f84a                	sd	s2,48(sp)
    800021a6:	f44e                	sd	s3,40(sp)
    800021a8:	f052                	sd	s4,32(sp)
    800021aa:	ec56                	sd	s5,24(sp)
    800021ac:	e85a                	sd	s6,16(sp)
    800021ae:	e45e                	sd	s7,8(sp)
    800021b0:	e062                	sd	s8,0(sp)
    800021b2:	0880                	addi	s0,sp,80
    800021b4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021b6:	f18ff0ef          	jal	800018ce <myproc>
    800021ba:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021bc:	00010517          	auipc	a0,0x10
    800021c0:	1d450513          	addi	a0,a0,468 # 80012390 <wait_lock>
    800021c4:	a0bfe0ef          	jal	80000bce <acquire>
    havekids = 0;
    800021c8:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800021ca:	4a15                	li	s4,5
        havekids = 1;
    800021cc:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800021ce:	00016997          	auipc	s3,0x16
    800021d2:	1da98993          	addi	s3,s3,474 # 800183a8 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021d6:	00010c17          	auipc	s8,0x10
    800021da:	1bac0c13          	addi	s8,s8,442 # 80012390 <wait_lock>
    800021de:	a871                	j	8000227a <kwait+0xde>
          pid = pp->pid;
    800021e0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800021e4:	000b0c63          	beqz	s6,800021fc <kwait+0x60>
    800021e8:	4691                	li	a3,4
    800021ea:	02c48613          	addi	a2,s1,44
    800021ee:	85da                	mv	a1,s6
    800021f0:	05093503          	ld	a0,80(s2)
    800021f4:	beeff0ef          	jal	800015e2 <copyout>
    800021f8:	02054b63          	bltz	a0,8000222e <kwait+0x92>
          freeproc(pp);
    800021fc:	8526                	mv	a0,s1
    800021fe:	8a1ff0ef          	jal	80001a9e <freeproc>
          release(&pp->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	a63fe0ef          	jal	80000c66 <release>
          release(&wait_lock);
    80002208:	00010517          	auipc	a0,0x10
    8000220c:	18850513          	addi	a0,a0,392 # 80012390 <wait_lock>
    80002210:	a57fe0ef          	jal	80000c66 <release>
}
    80002214:	854e                	mv	a0,s3
    80002216:	60a6                	ld	ra,72(sp)
    80002218:	6406                	ld	s0,64(sp)
    8000221a:	74e2                	ld	s1,56(sp)
    8000221c:	7942                	ld	s2,48(sp)
    8000221e:	79a2                	ld	s3,40(sp)
    80002220:	7a02                	ld	s4,32(sp)
    80002222:	6ae2                	ld	s5,24(sp)
    80002224:	6b42                	ld	s6,16(sp)
    80002226:	6ba2                	ld	s7,8(sp)
    80002228:	6c02                	ld	s8,0(sp)
    8000222a:	6161                	addi	sp,sp,80
    8000222c:	8082                	ret
            release(&pp->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	a37fe0ef          	jal	80000c66 <release>
            release(&wait_lock);
    80002234:	00010517          	auipc	a0,0x10
    80002238:	15c50513          	addi	a0,a0,348 # 80012390 <wait_lock>
    8000223c:	a2bfe0ef          	jal	80000c66 <release>
            return -1;
    80002240:	59fd                	li	s3,-1
    80002242:	bfc9                	j	80002214 <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002244:	17048493          	addi	s1,s1,368
    80002248:	03348063          	beq	s1,s3,80002268 <kwait+0xcc>
      if(pp->parent == p){
    8000224c:	7c9c                	ld	a5,56(s1)
    8000224e:	ff279be3          	bne	a5,s2,80002244 <kwait+0xa8>
        acquire(&pp->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	97bfe0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    80002258:	4c9c                	lw	a5,24(s1)
    8000225a:	f94783e3          	beq	a5,s4,800021e0 <kwait+0x44>
        release(&pp->lock);
    8000225e:	8526                	mv	a0,s1
    80002260:	a07fe0ef          	jal	80000c66 <release>
        havekids = 1;
    80002264:	8756                	mv	a4,s5
    80002266:	bff9                	j	80002244 <kwait+0xa8>
    if(!havekids || killed(p)){
    80002268:	cf19                	beqz	a4,80002286 <kwait+0xea>
    8000226a:	854a                	mv	a0,s2
    8000226c:	f07ff0ef          	jal	80002172 <killed>
    80002270:	e919                	bnez	a0,80002286 <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002272:	85e2                	mv	a1,s8
    80002274:	854a                	mv	a0,s2
    80002276:	cc5ff0ef          	jal	80001f3a <sleep>
    havekids = 0;
    8000227a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227c:	00010497          	auipc	s1,0x10
    80002280:	52c48493          	addi	s1,s1,1324 # 800127a8 <proc>
    80002284:	b7e1                	j	8000224c <kwait+0xb0>
      release(&wait_lock);
    80002286:	00010517          	auipc	a0,0x10
    8000228a:	10a50513          	addi	a0,a0,266 # 80012390 <wait_lock>
    8000228e:	9d9fe0ef          	jal	80000c66 <release>
      return -1;
    80002292:	59fd                	li	s3,-1
    80002294:	b741                	j	80002214 <kwait+0x78>

0000000080002296 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002296:	7179                	addi	sp,sp,-48
    80002298:	f406                	sd	ra,40(sp)
    8000229a:	f022                	sd	s0,32(sp)
    8000229c:	ec26                	sd	s1,24(sp)
    8000229e:	e84a                	sd	s2,16(sp)
    800022a0:	e44e                	sd	s3,8(sp)
    800022a2:	e052                	sd	s4,0(sp)
    800022a4:	1800                	addi	s0,sp,48
    800022a6:	84aa                	mv	s1,a0
    800022a8:	892e                	mv	s2,a1
    800022aa:	89b2                	mv	s3,a2
    800022ac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022ae:	e20ff0ef          	jal	800018ce <myproc>
  if(user_dst){
    800022b2:	cc99                	beqz	s1,800022d0 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    800022b4:	86d2                	mv	a3,s4
    800022b6:	864e                	mv	a2,s3
    800022b8:	85ca                	mv	a1,s2
    800022ba:	6928                	ld	a0,80(a0)
    800022bc:	b26ff0ef          	jal	800015e2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800022c0:	70a2                	ld	ra,40(sp)
    800022c2:	7402                	ld	s0,32(sp)
    800022c4:	64e2                	ld	s1,24(sp)
    800022c6:	6942                	ld	s2,16(sp)
    800022c8:	69a2                	ld	s3,8(sp)
    800022ca:	6a02                	ld	s4,0(sp)
    800022cc:	6145                	addi	sp,sp,48
    800022ce:	8082                	ret
    memmove((char *)dst, src, len);
    800022d0:	000a061b          	sext.w	a2,s4
    800022d4:	85ce                	mv	a1,s3
    800022d6:	854a                	mv	a0,s2
    800022d8:	a27fe0ef          	jal	80000cfe <memmove>
    return 0;
    800022dc:	8526                	mv	a0,s1
    800022de:	b7cd                	j	800022c0 <either_copyout+0x2a>

00000000800022e0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800022e0:	7179                	addi	sp,sp,-48
    800022e2:	f406                	sd	ra,40(sp)
    800022e4:	f022                	sd	s0,32(sp)
    800022e6:	ec26                	sd	s1,24(sp)
    800022e8:	e84a                	sd	s2,16(sp)
    800022ea:	e44e                	sd	s3,8(sp)
    800022ec:	e052                	sd	s4,0(sp)
    800022ee:	1800                	addi	s0,sp,48
    800022f0:	892a                	mv	s2,a0
    800022f2:	84ae                	mv	s1,a1
    800022f4:	89b2                	mv	s3,a2
    800022f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022f8:	dd6ff0ef          	jal	800018ce <myproc>
  if(user_src){
    800022fc:	cc99                	beqz	s1,8000231a <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    800022fe:	86d2                	mv	a3,s4
    80002300:	864e                	mv	a2,s3
    80002302:	85ca                	mv	a1,s2
    80002304:	6928                	ld	a0,80(a0)
    80002306:	bc0ff0ef          	jal	800016c6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000230a:	70a2                	ld	ra,40(sp)
    8000230c:	7402                	ld	s0,32(sp)
    8000230e:	64e2                	ld	s1,24(sp)
    80002310:	6942                	ld	s2,16(sp)
    80002312:	69a2                	ld	s3,8(sp)
    80002314:	6a02                	ld	s4,0(sp)
    80002316:	6145                	addi	sp,sp,48
    80002318:	8082                	ret
    memmove(dst, (char*)src, len);
    8000231a:	000a061b          	sext.w	a2,s4
    8000231e:	85ce                	mv	a1,s3
    80002320:	854a                	mv	a0,s2
    80002322:	9ddfe0ef          	jal	80000cfe <memmove>
    return 0;
    80002326:	8526                	mv	a0,s1
    80002328:	b7cd                	j	8000230a <either_copyin+0x2a>

000000008000232a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000232a:	715d                	addi	sp,sp,-80
    8000232c:	e486                	sd	ra,72(sp)
    8000232e:	e0a2                	sd	s0,64(sp)
    80002330:	fc26                	sd	s1,56(sp)
    80002332:	f84a                	sd	s2,48(sp)
    80002334:	f44e                	sd	s3,40(sp)
    80002336:	f052                	sd	s4,32(sp)
    80002338:	ec56                	sd	s5,24(sp)
    8000233a:	e85a                	sd	s6,16(sp)
    8000233c:	e45e                	sd	s7,8(sp)
    8000233e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002340:	00005517          	auipc	a0,0x5
    80002344:	d3850513          	addi	a0,a0,-712 # 80007078 <etext+0x78>
    80002348:	9b2fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000234c:	00010497          	auipc	s1,0x10
    80002350:	5b448493          	addi	s1,s1,1460 # 80012900 <proc+0x158>
    80002354:	00016917          	auipc	s2,0x16
    80002358:	1ac90913          	addi	s2,s2,428 # 80018500 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000235c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000235e:	00005997          	auipc	s3,0x5
    80002362:	ea298993          	addi	s3,s3,-350 # 80007200 <etext+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    80002366:	00005a97          	auipc	s5,0x5
    8000236a:	ea2a8a93          	addi	s5,s5,-350 # 80007208 <etext+0x208>
    printf("\n");
    8000236e:	00005a17          	auipc	s4,0x5
    80002372:	d0aa0a13          	addi	s4,s4,-758 # 80007078 <etext+0x78>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002376:	00005b97          	auipc	s7,0x5
    8000237a:	3d2b8b93          	addi	s7,s7,978 # 80007748 <states.0>
    8000237e:	a829                	j	80002398 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002380:	ed86a583          	lw	a1,-296(a3)
    80002384:	8556                	mv	a0,s5
    80002386:	974fe0ef          	jal	800004fa <printf>
    printf("\n");
    8000238a:	8552                	mv	a0,s4
    8000238c:	96efe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002390:	17048493          	addi	s1,s1,368
    80002394:	03248263          	beq	s1,s2,800023b8 <procdump+0x8e>
    if(p->state == UNUSED)
    80002398:	86a6                	mv	a3,s1
    8000239a:	ec04a783          	lw	a5,-320(s1)
    8000239e:	dbed                	beqz	a5,80002390 <procdump+0x66>
      state = "???";
    800023a0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800023a2:	fcfb6fe3          	bltu	s6,a5,80002380 <procdump+0x56>
    800023a6:	02079713          	slli	a4,a5,0x20
    800023aa:	01d75793          	srli	a5,a4,0x1d
    800023ae:	97de                	add	a5,a5,s7
    800023b0:	6390                	ld	a2,0(a5)
    800023b2:	f679                	bnez	a2,80002380 <procdump+0x56>
      state = "???";
    800023b4:	864e                	mv	a2,s3
    800023b6:	b7e9                	j	80002380 <procdump+0x56>
  }
}
    800023b8:	60a6                	ld	ra,72(sp)
    800023ba:	6406                	ld	s0,64(sp)
    800023bc:	74e2                	ld	s1,56(sp)
    800023be:	7942                	ld	s2,48(sp)
    800023c0:	79a2                	ld	s3,40(sp)
    800023c2:	7a02                	ld	s4,32(sp)
    800023c4:	6ae2                	ld	s5,24(sp)
    800023c6:	6b42                	ld	s6,16(sp)
    800023c8:	6ba2                	ld	s7,8(sp)
    800023ca:	6161                	addi	sp,sp,80
    800023cc:	8082                	ret

00000000800023ce <setpriority>:

int
setpriority(int pid, int priority)
{
  if(priority < 0) return -1; // Invalid Priority
    800023ce:	0605c163          	bltz	a1,80002430 <setpriority+0x62>
{
    800023d2:	7179                	addi	sp,sp,-48
    800023d4:	f406                	sd	ra,40(sp)
    800023d6:	f022                	sd	s0,32(sp)
    800023d8:	ec26                	sd	s1,24(sp)
    800023da:	e84a                	sd	s2,16(sp)
    800023dc:	e44e                	sd	s3,8(sp)
    800023de:	e052                	sd	s4,0(sp)
    800023e0:	1800                	addi	s0,sp,48
    800023e2:	892a                	mv	s2,a0
    800023e4:	8a2e                	mv	s4,a1

  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023e6:	00010497          	auipc	s1,0x10
    800023ea:	3c248493          	addi	s1,s1,962 # 800127a8 <proc>
    800023ee:	00016997          	auipc	s3,0x16
    800023f2:	fba98993          	addi	s3,s3,-70 # 800183a8 <tickslock>
    acquire(&p->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	fd6fe0ef          	jal	80000bce <acquire>

    if(p->pid == pid){
    800023fc:	589c                	lw	a5,48(s1)
    800023fe:	01278b63          	beq	a5,s2,80002414 <setpriority+0x46>
      p->priority = priority;
      release(&p->lock);
      return 0;
    }

    release(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	863fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002408:	17048493          	addi	s1,s1,368
    8000240c:	ff3495e3          	bne	s1,s3,800023f6 <setpriority+0x28>
  }

  return -1; // Not Found
    80002410:	557d                	li	a0,-1
    80002412:	a039                	j	80002420 <setpriority+0x52>
      p->priority = priority;
    80002414:	1744a423          	sw	s4,360(s1)
      release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	84dfe0ef          	jal	80000c66 <release>
      return 0;
    8000241e:	4501                	li	a0,0
    80002420:	70a2                	ld	ra,40(sp)
    80002422:	7402                	ld	s0,32(sp)
    80002424:	64e2                	ld	s1,24(sp)
    80002426:	6942                	ld	s2,16(sp)
    80002428:	69a2                	ld	s3,8(sp)
    8000242a:	6a02                	ld	s4,0(sp)
    8000242c:	6145                	addi	sp,sp,48
    8000242e:	8082                	ret
  if(priority < 0) return -1; // Invalid Priority
    80002430:	557d                	li	a0,-1
    80002432:	8082                	ret

0000000080002434 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    80002434:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80002438:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    8000243c:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    8000243e:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002440:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80002444:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80002448:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    8000244c:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002450:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80002454:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80002458:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    8000245c:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002460:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002464:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80002468:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    8000246c:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002470:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002472:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002474:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80002478:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    8000247c:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002480:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    80002484:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    80002488:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    8000248c:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002490:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80002494:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80002498:	0685bd83          	ld	s11,104(a1)
        
        ret
    8000249c:	8082                	ret

000000008000249e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000249e:	1141                	addi	sp,sp,-16
    800024a0:	e406                	sd	ra,8(sp)
    800024a2:	e022                	sd	s0,0(sp)
    800024a4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800024a6:	00005597          	auipc	a1,0x5
    800024aa:	da258593          	addi	a1,a1,-606 # 80007248 <etext+0x248>
    800024ae:	00016517          	auipc	a0,0x16
    800024b2:	efa50513          	addi	a0,a0,-262 # 800183a8 <tickslock>
    800024b6:	e98fe0ef          	jal	80000b4e <initlock>
}
    800024ba:	60a2                	ld	ra,8(sp)
    800024bc:	6402                	ld	s0,0(sp)
    800024be:	0141                	addi	sp,sp,16
    800024c0:	8082                	ret

00000000800024c2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800024c2:	1141                	addi	sp,sp,-16
    800024c4:	e422                	sd	s0,8(sp)
    800024c6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800024c8:	00003797          	auipc	a5,0x3
    800024cc:	ff878793          	addi	a5,a5,-8 # 800054c0 <kernelvec>
    800024d0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800024d4:	6422                	ld	s0,8(sp)
    800024d6:	0141                	addi	sp,sp,16
    800024d8:	8082                	ret

00000000800024da <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800024da:	1141                	addi	sp,sp,-16
    800024dc:	e406                	sd	ra,8(sp)
    800024de:	e022                	sd	s0,0(sp)
    800024e0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800024e2:	becff0ef          	jal	800018ce <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800024ea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024ec:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800024f0:	04000737          	lui	a4,0x4000
    800024f4:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800024f6:	0732                	slli	a4,a4,0xc
    800024f8:	00004797          	auipc	a5,0x4
    800024fc:	b0878793          	addi	a5,a5,-1272 # 80006000 <_trampoline>
    80002500:	00004697          	auipc	a3,0x4
    80002504:	b0068693          	addi	a3,a3,-1280 # 80006000 <_trampoline>
    80002508:	8f95                	sub	a5,a5,a3
    8000250a:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000250c:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002510:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002512:	18002773          	csrr	a4,satp
    80002516:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002518:	6d38                	ld	a4,88(a0)
    8000251a:	613c                	ld	a5,64(a0)
    8000251c:	6685                	lui	a3,0x1
    8000251e:	97b6                	add	a5,a5,a3
    80002520:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002522:	6d3c                	ld	a5,88(a0)
    80002524:	00000717          	auipc	a4,0x0
    80002528:	0f870713          	addi	a4,a4,248 # 8000261c <usertrap>
    8000252c:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000252e:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002530:	8712                	mv	a4,tp
    80002532:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002534:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002538:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000253c:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002540:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002544:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002546:	6f9c                	ld	a5,24(a5)
    80002548:	14179073          	csrw	sepc,a5
}
    8000254c:	60a2                	ld	ra,8(sp)
    8000254e:	6402                	ld	s0,0(sp)
    80002550:	0141                	addi	sp,sp,16
    80002552:	8082                	ret

0000000080002554 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002554:	1101                	addi	sp,sp,-32
    80002556:	ec06                	sd	ra,24(sp)
    80002558:	e822                	sd	s0,16(sp)
    8000255a:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    8000255c:	b46ff0ef          	jal	800018a2 <cpuid>
    80002560:	cd11                	beqz	a0,8000257c <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002562:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    80002566:	000f4737          	lui	a4,0xf4
    8000256a:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    8000256e:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002570:	14d79073          	csrw	stimecmp,a5
}
    80002574:	60e2                	ld	ra,24(sp)
    80002576:	6442                	ld	s0,16(sp)
    80002578:	6105                	addi	sp,sp,32
    8000257a:	8082                	ret
    8000257c:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    8000257e:	00016497          	auipc	s1,0x16
    80002582:	e2a48493          	addi	s1,s1,-470 # 800183a8 <tickslock>
    80002586:	8526                	mv	a0,s1
    80002588:	e46fe0ef          	jal	80000bce <acquire>
    ticks++;
    8000258c:	00008517          	auipc	a0,0x8
    80002590:	cec50513          	addi	a0,a0,-788 # 8000a278 <ticks>
    80002594:	411c                	lw	a5,0(a0)
    80002596:	2785                	addiw	a5,a5,1
    80002598:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    8000259a:	9edff0ef          	jal	80001f86 <wakeup>
    release(&tickslock);
    8000259e:	8526                	mv	a0,s1
    800025a0:	ec6fe0ef          	jal	80000c66 <release>
    800025a4:	64a2                	ld	s1,8(sp)
    800025a6:	bf75                	j	80002562 <clockintr+0xe>

00000000800025a8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800025a8:	1101                	addi	sp,sp,-32
    800025aa:	ec06                	sd	ra,24(sp)
    800025ac:	e822                	sd	s0,16(sp)
    800025ae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800025b0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800025b4:	57fd                	li	a5,-1
    800025b6:	17fe                	slli	a5,a5,0x3f
    800025b8:	07a5                	addi	a5,a5,9
    800025ba:	00f70c63          	beq	a4,a5,800025d2 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800025be:	57fd                	li	a5,-1
    800025c0:	17fe                	slli	a5,a5,0x3f
    800025c2:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800025c4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800025c6:	04f70763          	beq	a4,a5,80002614 <devintr+0x6c>
  }
}
    800025ca:	60e2                	ld	ra,24(sp)
    800025cc:	6442                	ld	s0,16(sp)
    800025ce:	6105                	addi	sp,sp,32
    800025d0:	8082                	ret
    800025d2:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    800025d4:	799020ef          	jal	8000556c <plic_claim>
    800025d8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800025da:	47a9                	li	a5,10
    800025dc:	00f50963          	beq	a0,a5,800025ee <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    800025e0:	4785                	li	a5,1
    800025e2:	00f50963          	beq	a0,a5,800025f4 <devintr+0x4c>
    return 1;
    800025e6:	4505                	li	a0,1
    } else if(irq){
    800025e8:	e889                	bnez	s1,800025fa <devintr+0x52>
    800025ea:	64a2                	ld	s1,8(sp)
    800025ec:	bff9                	j	800025ca <devintr+0x22>
      uartintr();
    800025ee:	bc2fe0ef          	jal	800009b0 <uartintr>
    if(irq)
    800025f2:	a819                	j	80002608 <devintr+0x60>
      virtio_disk_intr();
    800025f4:	43e030ef          	jal	80005a32 <virtio_disk_intr>
    if(irq)
    800025f8:	a801                	j	80002608 <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    800025fa:	85a6                	mv	a1,s1
    800025fc:	00005517          	auipc	a0,0x5
    80002600:	c5450513          	addi	a0,a0,-940 # 80007250 <etext+0x250>
    80002604:	ef7fd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    80002608:	8526                	mv	a0,s1
    8000260a:	783020ef          	jal	8000558c <plic_complete>
    return 1;
    8000260e:	4505                	li	a0,1
    80002610:	64a2                	ld	s1,8(sp)
    80002612:	bf65                	j	800025ca <devintr+0x22>
    clockintr();
    80002614:	f41ff0ef          	jal	80002554 <clockintr>
    return 2;
    80002618:	4509                	li	a0,2
    8000261a:	bf45                	j	800025ca <devintr+0x22>

000000008000261c <usertrap>:
{
    8000261c:	1101                	addi	sp,sp,-32
    8000261e:	ec06                	sd	ra,24(sp)
    80002620:	e822                	sd	s0,16(sp)
    80002622:	e426                	sd	s1,8(sp)
    80002624:	e04a                	sd	s2,0(sp)
    80002626:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002628:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000262c:	1007f793          	andi	a5,a5,256
    80002630:	eba5                	bnez	a5,800026a0 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002632:	00003797          	auipc	a5,0x3
    80002636:	e8e78793          	addi	a5,a5,-370 # 800054c0 <kernelvec>
    8000263a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000263e:	a90ff0ef          	jal	800018ce <myproc>
    80002642:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002644:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002646:	14102773          	csrr	a4,sepc
    8000264a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000264c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002650:	47a1                	li	a5,8
    80002652:	04f70d63          	beq	a4,a5,800026ac <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    80002656:	f53ff0ef          	jal	800025a8 <devintr>
    8000265a:	892a                	mv	s2,a0
    8000265c:	e945                	bnez	a0,8000270c <usertrap+0xf0>
    8000265e:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002662:	47bd                	li	a5,15
    80002664:	08f70863          	beq	a4,a5,800026f4 <usertrap+0xd8>
    80002668:	14202773          	csrr	a4,scause
    8000266c:	47b5                	li	a5,13
    8000266e:	08f70363          	beq	a4,a5,800026f4 <usertrap+0xd8>
    80002672:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    80002676:	5890                	lw	a2,48(s1)
    80002678:	00005517          	auipc	a0,0x5
    8000267c:	c1850513          	addi	a0,a0,-1000 # 80007290 <etext+0x290>
    80002680:	e7bfd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002684:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002688:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    8000268c:	00005517          	auipc	a0,0x5
    80002690:	c3450513          	addi	a0,a0,-972 # 800072c0 <etext+0x2c0>
    80002694:	e67fd0ef          	jal	800004fa <printf>
    setkilled(p);
    80002698:	8526                	mv	a0,s1
    8000269a:	ab5ff0ef          	jal	8000214e <setkilled>
    8000269e:	a035                	j	800026ca <usertrap+0xae>
    panic("usertrap: not from user mode");
    800026a0:	00005517          	auipc	a0,0x5
    800026a4:	bd050513          	addi	a0,a0,-1072 # 80007270 <etext+0x270>
    800026a8:	938fe0ef          	jal	800007e0 <panic>
    if(killed(p))
    800026ac:	ac7ff0ef          	jal	80002172 <killed>
    800026b0:	ed15                	bnez	a0,800026ec <usertrap+0xd0>
    p->trapframe->epc += 4;
    800026b2:	6cb8                	ld	a4,88(s1)
    800026b4:	6f1c                	ld	a5,24(a4)
    800026b6:	0791                	addi	a5,a5,4
    800026b8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800026be:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c2:	10079073          	csrw	sstatus,a5
    syscall();
    800026c6:	246000ef          	jal	8000290c <syscall>
  if(killed(p))
    800026ca:	8526                	mv	a0,s1
    800026cc:	aa7ff0ef          	jal	80002172 <killed>
    800026d0:	e139                	bnez	a0,80002716 <usertrap+0xfa>
  prepare_return();
    800026d2:	e09ff0ef          	jal	800024da <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800026d6:	68a8                	ld	a0,80(s1)
    800026d8:	8131                	srli	a0,a0,0xc
    800026da:	57fd                	li	a5,-1
    800026dc:	17fe                	slli	a5,a5,0x3f
    800026de:	8d5d                	or	a0,a0,a5
}
    800026e0:	60e2                	ld	ra,24(sp)
    800026e2:	6442                	ld	s0,16(sp)
    800026e4:	64a2                	ld	s1,8(sp)
    800026e6:	6902                	ld	s2,0(sp)
    800026e8:	6105                	addi	sp,sp,32
    800026ea:	8082                	ret
      kexit(-1);
    800026ec:	557d                	li	a0,-1
    800026ee:	959ff0ef          	jal	80002046 <kexit>
    800026f2:	b7c1                	j	800026b2 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800026f4:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026f8:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    800026fc:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    800026fe:	00163613          	seqz	a2,a2
    80002702:	68a8                	ld	a0,80(s1)
    80002704:	e5dfe0ef          	jal	80001560 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002708:	f169                	bnez	a0,800026ca <usertrap+0xae>
    8000270a:	b7a5                	j	80002672 <usertrap+0x56>
  if(killed(p))
    8000270c:	8526                	mv	a0,s1
    8000270e:	a65ff0ef          	jal	80002172 <killed>
    80002712:	c511                	beqz	a0,8000271e <usertrap+0x102>
    80002714:	a011                	j	80002718 <usertrap+0xfc>
    80002716:	4901                	li	s2,0
    kexit(-1);
    80002718:	557d                	li	a0,-1
    8000271a:	92dff0ef          	jal	80002046 <kexit>
  if(which_dev == 2)
    8000271e:	4789                	li	a5,2
    80002720:	faf919e3          	bne	s2,a5,800026d2 <usertrap+0xb6>
    yield();
    80002724:	feaff0ef          	jal	80001f0e <yield>
    80002728:	b76d                	j	800026d2 <usertrap+0xb6>

000000008000272a <kerneltrap>:
{
    8000272a:	7179                	addi	sp,sp,-48
    8000272c:	f406                	sd	ra,40(sp)
    8000272e:	f022                	sd	s0,32(sp)
    80002730:	ec26                	sd	s1,24(sp)
    80002732:	e84a                	sd	s2,16(sp)
    80002734:	e44e                	sd	s3,8(sp)
    80002736:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002738:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000273c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002740:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002744:	1004f793          	andi	a5,s1,256
    80002748:	c795                	beqz	a5,80002774 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000274a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000274e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002750:	eb85                	bnez	a5,80002780 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002752:	e57ff0ef          	jal	800025a8 <devintr>
    80002756:	c91d                	beqz	a0,8000278c <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    80002758:	4789                	li	a5,2
    8000275a:	04f50a63          	beq	a0,a5,800027ae <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000275e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002762:	10049073          	csrw	sstatus,s1
}
    80002766:	70a2                	ld	ra,40(sp)
    80002768:	7402                	ld	s0,32(sp)
    8000276a:	64e2                	ld	s1,24(sp)
    8000276c:	6942                	ld	s2,16(sp)
    8000276e:	69a2                	ld	s3,8(sp)
    80002770:	6145                	addi	sp,sp,48
    80002772:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002774:	00005517          	auipc	a0,0x5
    80002778:	b7450513          	addi	a0,a0,-1164 # 800072e8 <etext+0x2e8>
    8000277c:	864fe0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    80002780:	00005517          	auipc	a0,0x5
    80002784:	b9050513          	addi	a0,a0,-1136 # 80007310 <etext+0x310>
    80002788:	858fe0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000278c:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002790:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    80002794:	85ce                	mv	a1,s3
    80002796:	00005517          	auipc	a0,0x5
    8000279a:	b9a50513          	addi	a0,a0,-1126 # 80007330 <etext+0x330>
    8000279e:	d5dfd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    800027a2:	00005517          	auipc	a0,0x5
    800027a6:	bb650513          	addi	a0,a0,-1098 # 80007358 <etext+0x358>
    800027aa:	836fe0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0)
    800027ae:	920ff0ef          	jal	800018ce <myproc>
    800027b2:	d555                	beqz	a0,8000275e <kerneltrap+0x34>
    yield();
    800027b4:	f5aff0ef          	jal	80001f0e <yield>
    800027b8:	b75d                	j	8000275e <kerneltrap+0x34>

00000000800027ba <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800027ba:	1101                	addi	sp,sp,-32
    800027bc:	ec06                	sd	ra,24(sp)
    800027be:	e822                	sd	s0,16(sp)
    800027c0:	e426                	sd	s1,8(sp)
    800027c2:	1000                	addi	s0,sp,32
    800027c4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800027c6:	908ff0ef          	jal	800018ce <myproc>
  switch (n) {
    800027ca:	4795                	li	a5,5
    800027cc:	0497e163          	bltu	a5,s1,8000280e <argraw+0x54>
    800027d0:	048a                	slli	s1,s1,0x2
    800027d2:	00005717          	auipc	a4,0x5
    800027d6:	fa670713          	addi	a4,a4,-90 # 80007778 <states.0+0x30>
    800027da:	94ba                	add	s1,s1,a4
    800027dc:	409c                	lw	a5,0(s1)
    800027de:	97ba                	add	a5,a5,a4
    800027e0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800027e2:	6d3c                	ld	a5,88(a0)
    800027e4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800027e6:	60e2                	ld	ra,24(sp)
    800027e8:	6442                	ld	s0,16(sp)
    800027ea:	64a2                	ld	s1,8(sp)
    800027ec:	6105                	addi	sp,sp,32
    800027ee:	8082                	ret
    return p->trapframe->a1;
    800027f0:	6d3c                	ld	a5,88(a0)
    800027f2:	7fa8                	ld	a0,120(a5)
    800027f4:	bfcd                	j	800027e6 <argraw+0x2c>
    return p->trapframe->a2;
    800027f6:	6d3c                	ld	a5,88(a0)
    800027f8:	63c8                	ld	a0,128(a5)
    800027fa:	b7f5                	j	800027e6 <argraw+0x2c>
    return p->trapframe->a3;
    800027fc:	6d3c                	ld	a5,88(a0)
    800027fe:	67c8                	ld	a0,136(a5)
    80002800:	b7dd                	j	800027e6 <argraw+0x2c>
    return p->trapframe->a4;
    80002802:	6d3c                	ld	a5,88(a0)
    80002804:	6bc8                	ld	a0,144(a5)
    80002806:	b7c5                	j	800027e6 <argraw+0x2c>
    return p->trapframe->a5;
    80002808:	6d3c                	ld	a5,88(a0)
    8000280a:	6fc8                	ld	a0,152(a5)
    8000280c:	bfe9                	j	800027e6 <argraw+0x2c>
  panic("argraw");
    8000280e:	00005517          	auipc	a0,0x5
    80002812:	b5a50513          	addi	a0,a0,-1190 # 80007368 <etext+0x368>
    80002816:	fcbfd0ef          	jal	800007e0 <panic>

000000008000281a <fetchaddr>:
{
    8000281a:	1101                	addi	sp,sp,-32
    8000281c:	ec06                	sd	ra,24(sp)
    8000281e:	e822                	sd	s0,16(sp)
    80002820:	e426                	sd	s1,8(sp)
    80002822:	e04a                	sd	s2,0(sp)
    80002824:	1000                	addi	s0,sp,32
    80002826:	84aa                	mv	s1,a0
    80002828:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000282a:	8a4ff0ef          	jal	800018ce <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000282e:	653c                	ld	a5,72(a0)
    80002830:	02f4f663          	bgeu	s1,a5,8000285c <fetchaddr+0x42>
    80002834:	00848713          	addi	a4,s1,8
    80002838:	02e7e463          	bltu	a5,a4,80002860 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000283c:	46a1                	li	a3,8
    8000283e:	8626                	mv	a2,s1
    80002840:	85ca                	mv	a1,s2
    80002842:	6928                	ld	a0,80(a0)
    80002844:	e83fe0ef          	jal	800016c6 <copyin>
    80002848:	00a03533          	snez	a0,a0
    8000284c:	40a00533          	neg	a0,a0
}
    80002850:	60e2                	ld	ra,24(sp)
    80002852:	6442                	ld	s0,16(sp)
    80002854:	64a2                	ld	s1,8(sp)
    80002856:	6902                	ld	s2,0(sp)
    80002858:	6105                	addi	sp,sp,32
    8000285a:	8082                	ret
    return -1;
    8000285c:	557d                	li	a0,-1
    8000285e:	bfcd                	j	80002850 <fetchaddr+0x36>
    80002860:	557d                	li	a0,-1
    80002862:	b7fd                	j	80002850 <fetchaddr+0x36>

0000000080002864 <fetchstr>:
{
    80002864:	7179                	addi	sp,sp,-48
    80002866:	f406                	sd	ra,40(sp)
    80002868:	f022                	sd	s0,32(sp)
    8000286a:	ec26                	sd	s1,24(sp)
    8000286c:	e84a                	sd	s2,16(sp)
    8000286e:	e44e                	sd	s3,8(sp)
    80002870:	1800                	addi	s0,sp,48
    80002872:	892a                	mv	s2,a0
    80002874:	84ae                	mv	s1,a1
    80002876:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002878:	856ff0ef          	jal	800018ce <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    8000287c:	86ce                	mv	a3,s3
    8000287e:	864a                	mv	a2,s2
    80002880:	85a6                	mv	a1,s1
    80002882:	6928                	ld	a0,80(a0)
    80002884:	c05fe0ef          	jal	80001488 <copyinstr>
    80002888:	00054c63          	bltz	a0,800028a0 <fetchstr+0x3c>
  return strlen(buf);
    8000288c:	8526                	mv	a0,s1
    8000288e:	d84fe0ef          	jal	80000e12 <strlen>
}
    80002892:	70a2                	ld	ra,40(sp)
    80002894:	7402                	ld	s0,32(sp)
    80002896:	64e2                	ld	s1,24(sp)
    80002898:	6942                	ld	s2,16(sp)
    8000289a:	69a2                	ld	s3,8(sp)
    8000289c:	6145                	addi	sp,sp,48
    8000289e:	8082                	ret
    return -1;
    800028a0:	557d                	li	a0,-1
    800028a2:	bfc5                	j	80002892 <fetchstr+0x2e>

00000000800028a4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800028a4:	1101                	addi	sp,sp,-32
    800028a6:	ec06                	sd	ra,24(sp)
    800028a8:	e822                	sd	s0,16(sp)
    800028aa:	e426                	sd	s1,8(sp)
    800028ac:	1000                	addi	s0,sp,32
    800028ae:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800028b0:	f0bff0ef          	jal	800027ba <argraw>
    800028b4:	c088                	sw	a0,0(s1)
}
    800028b6:	60e2                	ld	ra,24(sp)
    800028b8:	6442                	ld	s0,16(sp)
    800028ba:	64a2                	ld	s1,8(sp)
    800028bc:	6105                	addi	sp,sp,32
    800028be:	8082                	ret

00000000800028c0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800028c0:	1101                	addi	sp,sp,-32
    800028c2:	ec06                	sd	ra,24(sp)
    800028c4:	e822                	sd	s0,16(sp)
    800028c6:	e426                	sd	s1,8(sp)
    800028c8:	1000                	addi	s0,sp,32
    800028ca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800028cc:	eefff0ef          	jal	800027ba <argraw>
    800028d0:	e088                	sd	a0,0(s1)
}
    800028d2:	60e2                	ld	ra,24(sp)
    800028d4:	6442                	ld	s0,16(sp)
    800028d6:	64a2                	ld	s1,8(sp)
    800028d8:	6105                	addi	sp,sp,32
    800028da:	8082                	ret

00000000800028dc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800028dc:	7179                	addi	sp,sp,-48
    800028de:	f406                	sd	ra,40(sp)
    800028e0:	f022                	sd	s0,32(sp)
    800028e2:	ec26                	sd	s1,24(sp)
    800028e4:	e84a                	sd	s2,16(sp)
    800028e6:	1800                	addi	s0,sp,48
    800028e8:	84ae                	mv	s1,a1
    800028ea:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800028ec:	fd840593          	addi	a1,s0,-40
    800028f0:	fd1ff0ef          	jal	800028c0 <argaddr>
  return fetchstr(addr, buf, max);
    800028f4:	864a                	mv	a2,s2
    800028f6:	85a6                	mv	a1,s1
    800028f8:	fd843503          	ld	a0,-40(s0)
    800028fc:	f69ff0ef          	jal	80002864 <fetchstr>
}
    80002900:	70a2                	ld	ra,40(sp)
    80002902:	7402                	ld	s0,32(sp)
    80002904:	64e2                	ld	s1,24(sp)
    80002906:	6942                	ld	s2,16(sp)
    80002908:	6145                	addi	sp,sp,48
    8000290a:	8082                	ret

000000008000290c <syscall>:
[SYS_printatomic]   sys_printatomic,
};

void
syscall(void)
{
    8000290c:	1101                	addi	sp,sp,-32
    8000290e:	ec06                	sd	ra,24(sp)
    80002910:	e822                	sd	s0,16(sp)
    80002912:	e426                	sd	s1,8(sp)
    80002914:	e04a                	sd	s2,0(sp)
    80002916:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002918:	fb7fe0ef          	jal	800018ce <myproc>
    8000291c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000291e:	05853903          	ld	s2,88(a0)
    80002922:	0a893783          	ld	a5,168(s2)
    80002926:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000292a:	37fd                	addiw	a5,a5,-1
    8000292c:	4759                	li	a4,22
    8000292e:	00f76f63          	bltu	a4,a5,8000294c <syscall+0x40>
    80002932:	00369713          	slli	a4,a3,0x3
    80002936:	00005797          	auipc	a5,0x5
    8000293a:	e5a78793          	addi	a5,a5,-422 # 80007790 <syscalls>
    8000293e:	97ba                	add	a5,a5,a4
    80002940:	639c                	ld	a5,0(a5)
    80002942:	c789                	beqz	a5,8000294c <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002944:	9782                	jalr	a5
    80002946:	06a93823          	sd	a0,112(s2)
    8000294a:	a829                	j	80002964 <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000294c:	15848613          	addi	a2,s1,344
    80002950:	588c                	lw	a1,48(s1)
    80002952:	00005517          	auipc	a0,0x5
    80002956:	a1e50513          	addi	a0,a0,-1506 # 80007370 <etext+0x370>
    8000295a:	ba1fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000295e:	6cbc                	ld	a5,88(s1)
    80002960:	577d                	li	a4,-1
    80002962:	fbb8                	sd	a4,112(a5)
  }
}
    80002964:	60e2                	ld	ra,24(sp)
    80002966:	6442                	ld	s0,16(sp)
    80002968:	64a2                	ld	s1,8(sp)
    8000296a:	6902                	ld	s2,0(sp)
    8000296c:	6105                	addi	sp,sp,32
    8000296e:	8082                	ret

0000000080002970 <sys_exit>:

extern struct proc proc[NPROC];

uint64
sys_exit(void)
{
    80002970:	1101                	addi	sp,sp,-32
    80002972:	ec06                	sd	ra,24(sp)
    80002974:	e822                	sd	s0,16(sp)
    80002976:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002978:	fec40593          	addi	a1,s0,-20
    8000297c:	4501                	li	a0,0
    8000297e:	f27ff0ef          	jal	800028a4 <argint>
  kexit(n);
    80002982:	fec42503          	lw	a0,-20(s0)
    80002986:	ec0ff0ef          	jal	80002046 <kexit>
  return 0;  // not reached
}
    8000298a:	4501                	li	a0,0
    8000298c:	60e2                	ld	ra,24(sp)
    8000298e:	6442                	ld	s0,16(sp)
    80002990:	6105                	addi	sp,sp,32
    80002992:	8082                	ret

0000000080002994 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002994:	1141                	addi	sp,sp,-16
    80002996:	e406                	sd	ra,8(sp)
    80002998:	e022                	sd	s0,0(sp)
    8000299a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000299c:	f33fe0ef          	jal	800018ce <myproc>
}
    800029a0:	5908                	lw	a0,48(a0)
    800029a2:	60a2                	ld	ra,8(sp)
    800029a4:	6402                	ld	s0,0(sp)
    800029a6:	0141                	addi	sp,sp,16
    800029a8:	8082                	ret

00000000800029aa <sys_fork>:

uint64
sys_fork(void)
{
    800029aa:	1141                	addi	sp,sp,-16
    800029ac:	e406                	sd	ra,8(sp)
    800029ae:	e022                	sd	s0,0(sp)
    800029b0:	0800                	addi	s0,sp,16
  return kfork();
    800029b2:	a84ff0ef          	jal	80001c36 <kfork>
}
    800029b6:	60a2                	ld	ra,8(sp)
    800029b8:	6402                	ld	s0,0(sp)
    800029ba:	0141                	addi	sp,sp,16
    800029bc:	8082                	ret

00000000800029be <sys_wait>:

uint64
sys_wait(void)
{
    800029be:	1101                	addi	sp,sp,-32
    800029c0:	ec06                	sd	ra,24(sp)
    800029c2:	e822                	sd	s0,16(sp)
    800029c4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800029c6:	fe840593          	addi	a1,s0,-24
    800029ca:	4501                	li	a0,0
    800029cc:	ef5ff0ef          	jal	800028c0 <argaddr>
  return kwait(p);
    800029d0:	fe843503          	ld	a0,-24(s0)
    800029d4:	fc8ff0ef          	jal	8000219c <kwait>
}
    800029d8:	60e2                	ld	ra,24(sp)
    800029da:	6442                	ld	s0,16(sp)
    800029dc:	6105                	addi	sp,sp,32
    800029de:	8082                	ret

00000000800029e0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800029e0:	7179                	addi	sp,sp,-48
    800029e2:	f406                	sd	ra,40(sp)
    800029e4:	f022                	sd	s0,32(sp)
    800029e6:	ec26                	sd	s1,24(sp)
    800029e8:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    800029ea:	fd840593          	addi	a1,s0,-40
    800029ee:	4501                	li	a0,0
    800029f0:	eb5ff0ef          	jal	800028a4 <argint>
  argint(1, &t);
    800029f4:	fdc40593          	addi	a1,s0,-36
    800029f8:	4505                	li	a0,1
    800029fa:	eabff0ef          	jal	800028a4 <argint>
  addr = myproc()->sz;
    800029fe:	ed1fe0ef          	jal	800018ce <myproc>
    80002a02:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002a04:	fdc42703          	lw	a4,-36(s0)
    80002a08:	4785                	li	a5,1
    80002a0a:	02f70763          	beq	a4,a5,80002a38 <sys_sbrk+0x58>
    80002a0e:	fd842783          	lw	a5,-40(s0)
    80002a12:	0207c363          	bltz	a5,80002a38 <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002a16:	97a6                	add	a5,a5,s1
    80002a18:	0297ee63          	bltu	a5,s1,80002a54 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    80002a1c:	02000737          	lui	a4,0x2000
    80002a20:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    80002a22:	0736                	slli	a4,a4,0xd
    80002a24:	02f76a63          	bltu	a4,a5,80002a58 <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    80002a28:	ea7fe0ef          	jal	800018ce <myproc>
    80002a2c:	fd842703          	lw	a4,-40(s0)
    80002a30:	653c                	ld	a5,72(a0)
    80002a32:	97ba                	add	a5,a5,a4
    80002a34:	e53c                	sd	a5,72(a0)
    80002a36:	a039                	j	80002a44 <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002a38:	fd842503          	lw	a0,-40(s0)
    80002a3c:	998ff0ef          	jal	80001bd4 <growproc>
    80002a40:	00054863          	bltz	a0,80002a50 <sys_sbrk+0x70>
  }
  return addr;
}
    80002a44:	8526                	mv	a0,s1
    80002a46:	70a2                	ld	ra,40(sp)
    80002a48:	7402                	ld	s0,32(sp)
    80002a4a:	64e2                	ld	s1,24(sp)
    80002a4c:	6145                	addi	sp,sp,48
    80002a4e:	8082                	ret
      return -1;
    80002a50:	54fd                	li	s1,-1
    80002a52:	bfcd                	j	80002a44 <sys_sbrk+0x64>
      return -1;
    80002a54:	54fd                	li	s1,-1
    80002a56:	b7fd                	j	80002a44 <sys_sbrk+0x64>
      return -1;
    80002a58:	54fd                	li	s1,-1
    80002a5a:	b7ed                	j	80002a44 <sys_sbrk+0x64>

0000000080002a5c <sys_pause>:

uint64
sys_pause(void)
{
    80002a5c:	7139                	addi	sp,sp,-64
    80002a5e:	fc06                	sd	ra,56(sp)
    80002a60:	f822                	sd	s0,48(sp)
    80002a62:	f04a                	sd	s2,32(sp)
    80002a64:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002a66:	fcc40593          	addi	a1,s0,-52
    80002a6a:	4501                	li	a0,0
    80002a6c:	e39ff0ef          	jal	800028a4 <argint>
  if(n < 0)
    80002a70:	fcc42783          	lw	a5,-52(s0)
    80002a74:	0607c763          	bltz	a5,80002ae2 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002a78:	00016517          	auipc	a0,0x16
    80002a7c:	93050513          	addi	a0,a0,-1744 # 800183a8 <tickslock>
    80002a80:	94efe0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80002a84:	00007917          	auipc	s2,0x7
    80002a88:	7f492903          	lw	s2,2036(s2) # 8000a278 <ticks>
  while(ticks - ticks0 < n){
    80002a8c:	fcc42783          	lw	a5,-52(s0)
    80002a90:	cf8d                	beqz	a5,80002aca <sys_pause+0x6e>
    80002a92:	f426                	sd	s1,40(sp)
    80002a94:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002a96:	00016997          	auipc	s3,0x16
    80002a9a:	91298993          	addi	s3,s3,-1774 # 800183a8 <tickslock>
    80002a9e:	00007497          	auipc	s1,0x7
    80002aa2:	7da48493          	addi	s1,s1,2010 # 8000a278 <ticks>
    if(killed(myproc())){
    80002aa6:	e29fe0ef          	jal	800018ce <myproc>
    80002aaa:	ec8ff0ef          	jal	80002172 <killed>
    80002aae:	ed0d                	bnez	a0,80002ae8 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002ab0:	85ce                	mv	a1,s3
    80002ab2:	8526                	mv	a0,s1
    80002ab4:	c86ff0ef          	jal	80001f3a <sleep>
  while(ticks - ticks0 < n){
    80002ab8:	409c                	lw	a5,0(s1)
    80002aba:	412787bb          	subw	a5,a5,s2
    80002abe:	fcc42703          	lw	a4,-52(s0)
    80002ac2:	fee7e2e3          	bltu	a5,a4,80002aa6 <sys_pause+0x4a>
    80002ac6:	74a2                	ld	s1,40(sp)
    80002ac8:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002aca:	00016517          	auipc	a0,0x16
    80002ace:	8de50513          	addi	a0,a0,-1826 # 800183a8 <tickslock>
    80002ad2:	994fe0ef          	jal	80000c66 <release>
  return 0;
    80002ad6:	4501                	li	a0,0
}
    80002ad8:	70e2                	ld	ra,56(sp)
    80002ada:	7442                	ld	s0,48(sp)
    80002adc:	7902                	ld	s2,32(sp)
    80002ade:	6121                	addi	sp,sp,64
    80002ae0:	8082                	ret
    n = 0;
    80002ae2:	fc042623          	sw	zero,-52(s0)
    80002ae6:	bf49                	j	80002a78 <sys_pause+0x1c>
      release(&tickslock);
    80002ae8:	00016517          	auipc	a0,0x16
    80002aec:	8c050513          	addi	a0,a0,-1856 # 800183a8 <tickslock>
    80002af0:	976fe0ef          	jal	80000c66 <release>
      return -1;
    80002af4:	557d                	li	a0,-1
    80002af6:	74a2                	ld	s1,40(sp)
    80002af8:	69e2                	ld	s3,24(sp)
    80002afa:	bff9                	j	80002ad8 <sys_pause+0x7c>

0000000080002afc <sys_kill>:

uint64
sys_kill(void)
{
    80002afc:	1101                	addi	sp,sp,-32
    80002afe:	ec06                	sd	ra,24(sp)
    80002b00:	e822                	sd	s0,16(sp)
    80002b02:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002b04:	fec40593          	addi	a1,s0,-20
    80002b08:	4501                	li	a0,0
    80002b0a:	d9bff0ef          	jal	800028a4 <argint>
  return kkill(pid);
    80002b0e:	fec42503          	lw	a0,-20(s0)
    80002b12:	dd6ff0ef          	jal	800020e8 <kkill>
}
    80002b16:	60e2                	ld	ra,24(sp)
    80002b18:	6442                	ld	s0,16(sp)
    80002b1a:	6105                	addi	sp,sp,32
    80002b1c:	8082                	ret

0000000080002b1e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002b1e:	1101                	addi	sp,sp,-32
    80002b20:	ec06                	sd	ra,24(sp)
    80002b22:	e822                	sd	s0,16(sp)
    80002b24:	e426                	sd	s1,8(sp)
    80002b26:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002b28:	00016517          	auipc	a0,0x16
    80002b2c:	88050513          	addi	a0,a0,-1920 # 800183a8 <tickslock>
    80002b30:	89efe0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80002b34:	00007497          	auipc	s1,0x7
    80002b38:	7444a483          	lw	s1,1860(s1) # 8000a278 <ticks>
  release(&tickslock);
    80002b3c:	00016517          	auipc	a0,0x16
    80002b40:	86c50513          	addi	a0,a0,-1940 # 800183a8 <tickslock>
    80002b44:	922fe0ef          	jal	80000c66 <release>
  return xticks;
}
    80002b48:	02049513          	slli	a0,s1,0x20
    80002b4c:	9101                	srli	a0,a0,0x20
    80002b4e:	60e2                	ld	ra,24(sp)
    80002b50:	6442                	ld	s0,16(sp)
    80002b52:	64a2                	ld	s1,8(sp)
    80002b54:	6105                	addi	sp,sp,32
    80002b56:	8082                	ret

0000000080002b58 <sys_setpriority>:

uint64
sys_setpriority(void)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	1000                	addi	s0,sp,32
  int pid, priority;

  argint(0, &pid);
    80002b60:	fec40593          	addi	a1,s0,-20
    80002b64:	4501                	li	a0,0
    80002b66:	d3fff0ef          	jal	800028a4 <argint>
  argint(1, &priority);
    80002b6a:	fe840593          	addi	a1,s0,-24
    80002b6e:	4505                	li	a0,1
    80002b70:	d35ff0ef          	jal	800028a4 <argint>

  return setpriority(pid, priority);
    80002b74:	fe842583          	lw	a1,-24(s0)
    80002b78:	fec42503          	lw	a0,-20(s0)
    80002b7c:	853ff0ef          	jal	800023ce <setpriority>
}
    80002b80:	60e2                	ld	ra,24(sp)
    80002b82:	6442                	ld	s0,16(sp)
    80002b84:	6105                	addi	sp,sp,32
    80002b86:	8082                	ret

0000000080002b88 <sys_printatomic>:

uint64
sys_printatomic(void)
{
    80002b88:	7179                	addi	sp,sp,-48
    80002b8a:	f406                	sd	ra,40(sp)
    80002b8c:	f022                	sd	s0,32(sp)
    80002b8e:	ec26                	sd	s1,24(sp)
    80002b90:	e84a                	sd	s2,16(sp)
    80002b92:	1800                	addi	s0,sp,48
  int pid;
  int prio = -1;
  argint(0, &pid);
    80002b94:	fdc40593          	addi	a1,s0,-36
    80002b98:	4501                	li	a0,0
    80002b9a:	d0bff0ef          	jal	800028a4 <argint>

  struct proc *p;
  for(p = proc; p < &proc[NPROC]; p++){
    80002b9e:	00010497          	auipc	s1,0x10
    80002ba2:	c0a48493          	addi	s1,s1,-1014 # 800127a8 <proc>
    80002ba6:	00016917          	auipc	s2,0x16
    80002baa:	80290913          	addi	s2,s2,-2046 # 800183a8 <tickslock>
    acquire(&p->lock);
    80002bae:	8526                	mv	a0,s1
    80002bb0:	81efe0ef          	jal	80000bce <acquire>

    if(p->pid == pid){
    80002bb4:	5898                	lw	a4,48(s1)
    80002bb6:	fdc42783          	lw	a5,-36(s0)
    80002bba:	00f70b63          	beq	a4,a5,80002bd0 <sys_printatomic+0x48>
      prio = p->priority;
      release(&p->lock);
      break;
    }
    release(&p->lock);
    80002bbe:	8526                	mv	a0,s1
    80002bc0:	8a6fe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002bc4:	17048493          	addi	s1,s1,368
    80002bc8:	ff2493e3          	bne	s1,s2,80002bae <sys_printatomic+0x26>
  int prio = -1;
    80002bcc:	597d                	li	s2,-1
    80002bce:	a031                	j	80002bda <sys_printatomic+0x52>
      prio = p->priority;
    80002bd0:	1684a903          	lw	s2,360(s1)
      release(&p->lock);
    80002bd4:	8526                	mv	a0,s1
    80002bd6:	890fe0ef          	jal	80000c66 <release>
  }

  printf("PID : %d Priority : %d \n",pid ,prio);
    80002bda:	864a                	mv	a2,s2
    80002bdc:	fdc42583          	lw	a1,-36(s0)
    80002be0:	00004517          	auipc	a0,0x4
    80002be4:	7b050513          	addi	a0,a0,1968 # 80007390 <etext+0x390>
    80002be8:	913fd0ef          	jal	800004fa <printf>

  return 0;
    80002bec:	4501                	li	a0,0
    80002bee:	70a2                	ld	ra,40(sp)
    80002bf0:	7402                	ld	s0,32(sp)
    80002bf2:	64e2                	ld	s1,24(sp)
    80002bf4:	6942                	ld	s2,16(sp)
    80002bf6:	6145                	addi	sp,sp,48
    80002bf8:	8082                	ret

0000000080002bfa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002bfa:	7179                	addi	sp,sp,-48
    80002bfc:	f406                	sd	ra,40(sp)
    80002bfe:	f022                	sd	s0,32(sp)
    80002c00:	ec26                	sd	s1,24(sp)
    80002c02:	e84a                	sd	s2,16(sp)
    80002c04:	e44e                	sd	s3,8(sp)
    80002c06:	e052                	sd	s4,0(sp)
    80002c08:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002c0a:	00004597          	auipc	a1,0x4
    80002c0e:	7a658593          	addi	a1,a1,1958 # 800073b0 <etext+0x3b0>
    80002c12:	00015517          	auipc	a0,0x15
    80002c16:	7ae50513          	addi	a0,a0,1966 # 800183c0 <bcache>
    80002c1a:	f35fd0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002c1e:	0001d797          	auipc	a5,0x1d
    80002c22:	7a278793          	addi	a5,a5,1954 # 800203c0 <bcache+0x8000>
    80002c26:	0001e717          	auipc	a4,0x1e
    80002c2a:	a0270713          	addi	a4,a4,-1534 # 80020628 <bcache+0x8268>
    80002c2e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002c32:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002c36:	00015497          	auipc	s1,0x15
    80002c3a:	7a248493          	addi	s1,s1,1954 # 800183d8 <bcache+0x18>
    b->next = bcache.head.next;
    80002c3e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002c40:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002c42:	00004a17          	auipc	s4,0x4
    80002c46:	776a0a13          	addi	s4,s4,1910 # 800073b8 <etext+0x3b8>
    b->next = bcache.head.next;
    80002c4a:	2b893783          	ld	a5,696(s2)
    80002c4e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002c50:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002c54:	85d2                	mv	a1,s4
    80002c56:	01048513          	addi	a0,s1,16
    80002c5a:	322010ef          	jal	80003f7c <initsleeplock>
    bcache.head.next->prev = b;
    80002c5e:	2b893783          	ld	a5,696(s2)
    80002c62:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002c64:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002c68:	45848493          	addi	s1,s1,1112
    80002c6c:	fd349fe3          	bne	s1,s3,80002c4a <binit+0x50>
  }
}
    80002c70:	70a2                	ld	ra,40(sp)
    80002c72:	7402                	ld	s0,32(sp)
    80002c74:	64e2                	ld	s1,24(sp)
    80002c76:	6942                	ld	s2,16(sp)
    80002c78:	69a2                	ld	s3,8(sp)
    80002c7a:	6a02                	ld	s4,0(sp)
    80002c7c:	6145                	addi	sp,sp,48
    80002c7e:	8082                	ret

0000000080002c80 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002c80:	7179                	addi	sp,sp,-48
    80002c82:	f406                	sd	ra,40(sp)
    80002c84:	f022                	sd	s0,32(sp)
    80002c86:	ec26                	sd	s1,24(sp)
    80002c88:	e84a                	sd	s2,16(sp)
    80002c8a:	e44e                	sd	s3,8(sp)
    80002c8c:	1800                	addi	s0,sp,48
    80002c8e:	892a                	mv	s2,a0
    80002c90:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002c92:	00015517          	auipc	a0,0x15
    80002c96:	72e50513          	addi	a0,a0,1838 # 800183c0 <bcache>
    80002c9a:	f35fd0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002c9e:	0001e497          	auipc	s1,0x1e
    80002ca2:	9da4b483          	ld	s1,-1574(s1) # 80020678 <bcache+0x82b8>
    80002ca6:	0001e797          	auipc	a5,0x1e
    80002caa:	98278793          	addi	a5,a5,-1662 # 80020628 <bcache+0x8268>
    80002cae:	02f48b63          	beq	s1,a5,80002ce4 <bread+0x64>
    80002cb2:	873e                	mv	a4,a5
    80002cb4:	a021                	j	80002cbc <bread+0x3c>
    80002cb6:	68a4                	ld	s1,80(s1)
    80002cb8:	02e48663          	beq	s1,a4,80002ce4 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002cbc:	449c                	lw	a5,8(s1)
    80002cbe:	ff279ce3          	bne	a5,s2,80002cb6 <bread+0x36>
    80002cc2:	44dc                	lw	a5,12(s1)
    80002cc4:	ff3799e3          	bne	a5,s3,80002cb6 <bread+0x36>
      b->refcnt++;
    80002cc8:	40bc                	lw	a5,64(s1)
    80002cca:	2785                	addiw	a5,a5,1
    80002ccc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002cce:	00015517          	auipc	a0,0x15
    80002cd2:	6f250513          	addi	a0,a0,1778 # 800183c0 <bcache>
    80002cd6:	f91fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002cda:	01048513          	addi	a0,s1,16
    80002cde:	2d4010ef          	jal	80003fb2 <acquiresleep>
      return b;
    80002ce2:	a889                	j	80002d34 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ce4:	0001e497          	auipc	s1,0x1e
    80002ce8:	98c4b483          	ld	s1,-1652(s1) # 80020670 <bcache+0x82b0>
    80002cec:	0001e797          	auipc	a5,0x1e
    80002cf0:	93c78793          	addi	a5,a5,-1732 # 80020628 <bcache+0x8268>
    80002cf4:	00f48863          	beq	s1,a5,80002d04 <bread+0x84>
    80002cf8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002cfa:	40bc                	lw	a5,64(s1)
    80002cfc:	cb91                	beqz	a5,80002d10 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002cfe:	64a4                	ld	s1,72(s1)
    80002d00:	fee49de3          	bne	s1,a4,80002cfa <bread+0x7a>
  panic("bget: no buffers");
    80002d04:	00004517          	auipc	a0,0x4
    80002d08:	6bc50513          	addi	a0,a0,1724 # 800073c0 <etext+0x3c0>
    80002d0c:	ad5fd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80002d10:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002d14:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002d18:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002d1c:	4785                	li	a5,1
    80002d1e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002d20:	00015517          	auipc	a0,0x15
    80002d24:	6a050513          	addi	a0,a0,1696 # 800183c0 <bcache>
    80002d28:	f3ffd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002d2c:	01048513          	addi	a0,s1,16
    80002d30:	282010ef          	jal	80003fb2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002d34:	409c                	lw	a5,0(s1)
    80002d36:	cb89                	beqz	a5,80002d48 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002d38:	8526                	mv	a0,s1
    80002d3a:	70a2                	ld	ra,40(sp)
    80002d3c:	7402                	ld	s0,32(sp)
    80002d3e:	64e2                	ld	s1,24(sp)
    80002d40:	6942                	ld	s2,16(sp)
    80002d42:	69a2                	ld	s3,8(sp)
    80002d44:	6145                	addi	sp,sp,48
    80002d46:	8082                	ret
    virtio_disk_rw(b, 0);
    80002d48:	4581                	li	a1,0
    80002d4a:	8526                	mv	a0,s1
    80002d4c:	2d5020ef          	jal	80005820 <virtio_disk_rw>
    b->valid = 1;
    80002d50:	4785                	li	a5,1
    80002d52:	c09c                	sw	a5,0(s1)
  return b;
    80002d54:	b7d5                	j	80002d38 <bread+0xb8>

0000000080002d56 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	e426                	sd	s1,8(sp)
    80002d5e:	1000                	addi	s0,sp,32
    80002d60:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002d62:	0541                	addi	a0,a0,16
    80002d64:	2cc010ef          	jal	80004030 <holdingsleep>
    80002d68:	c911                	beqz	a0,80002d7c <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002d6a:	4585                	li	a1,1
    80002d6c:	8526                	mv	a0,s1
    80002d6e:	2b3020ef          	jal	80005820 <virtio_disk_rw>
}
    80002d72:	60e2                	ld	ra,24(sp)
    80002d74:	6442                	ld	s0,16(sp)
    80002d76:	64a2                	ld	s1,8(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret
    panic("bwrite");
    80002d7c:	00004517          	auipc	a0,0x4
    80002d80:	65c50513          	addi	a0,a0,1628 # 800073d8 <etext+0x3d8>
    80002d84:	a5dfd0ef          	jal	800007e0 <panic>

0000000080002d88 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	e426                	sd	s1,8(sp)
    80002d90:	e04a                	sd	s2,0(sp)
    80002d92:	1000                	addi	s0,sp,32
    80002d94:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002d96:	01050913          	addi	s2,a0,16
    80002d9a:	854a                	mv	a0,s2
    80002d9c:	294010ef          	jal	80004030 <holdingsleep>
    80002da0:	c135                	beqz	a0,80002e04 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002da2:	854a                	mv	a0,s2
    80002da4:	254010ef          	jal	80003ff8 <releasesleep>

  acquire(&bcache.lock);
    80002da8:	00015517          	auipc	a0,0x15
    80002dac:	61850513          	addi	a0,a0,1560 # 800183c0 <bcache>
    80002db0:	e1ffd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002db4:	40bc                	lw	a5,64(s1)
    80002db6:	37fd                	addiw	a5,a5,-1
    80002db8:	0007871b          	sext.w	a4,a5
    80002dbc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002dbe:	e71d                	bnez	a4,80002dec <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002dc0:	68b8                	ld	a4,80(s1)
    80002dc2:	64bc                	ld	a5,72(s1)
    80002dc4:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002dc6:	68b8                	ld	a4,80(s1)
    80002dc8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002dca:	0001d797          	auipc	a5,0x1d
    80002dce:	5f678793          	addi	a5,a5,1526 # 800203c0 <bcache+0x8000>
    80002dd2:	2b87b703          	ld	a4,696(a5)
    80002dd6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002dd8:	0001e717          	auipc	a4,0x1e
    80002ddc:	85070713          	addi	a4,a4,-1968 # 80020628 <bcache+0x8268>
    80002de0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002de2:	2b87b703          	ld	a4,696(a5)
    80002de6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002de8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002dec:	00015517          	auipc	a0,0x15
    80002df0:	5d450513          	addi	a0,a0,1492 # 800183c0 <bcache>
    80002df4:	e73fd0ef          	jal	80000c66 <release>
}
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	64a2                	ld	s1,8(sp)
    80002dfe:	6902                	ld	s2,0(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret
    panic("brelse");
    80002e04:	00004517          	auipc	a0,0x4
    80002e08:	5dc50513          	addi	a0,a0,1500 # 800073e0 <etext+0x3e0>
    80002e0c:	9d5fd0ef          	jal	800007e0 <panic>

0000000080002e10 <bpin>:

void
bpin(struct buf *b) {
    80002e10:	1101                	addi	sp,sp,-32
    80002e12:	ec06                	sd	ra,24(sp)
    80002e14:	e822                	sd	s0,16(sp)
    80002e16:	e426                	sd	s1,8(sp)
    80002e18:	1000                	addi	s0,sp,32
    80002e1a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002e1c:	00015517          	auipc	a0,0x15
    80002e20:	5a450513          	addi	a0,a0,1444 # 800183c0 <bcache>
    80002e24:	dabfd0ef          	jal	80000bce <acquire>
  b->refcnt++;
    80002e28:	40bc                	lw	a5,64(s1)
    80002e2a:	2785                	addiw	a5,a5,1
    80002e2c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002e2e:	00015517          	auipc	a0,0x15
    80002e32:	59250513          	addi	a0,a0,1426 # 800183c0 <bcache>
    80002e36:	e31fd0ef          	jal	80000c66 <release>
}
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	64a2                	ld	s1,8(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret

0000000080002e44 <bunpin>:

void
bunpin(struct buf *b) {
    80002e44:	1101                	addi	sp,sp,-32
    80002e46:	ec06                	sd	ra,24(sp)
    80002e48:	e822                	sd	s0,16(sp)
    80002e4a:	e426                	sd	s1,8(sp)
    80002e4c:	1000                	addi	s0,sp,32
    80002e4e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002e50:	00015517          	auipc	a0,0x15
    80002e54:	57050513          	addi	a0,a0,1392 # 800183c0 <bcache>
    80002e58:	d77fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002e5c:	40bc                	lw	a5,64(s1)
    80002e5e:	37fd                	addiw	a5,a5,-1
    80002e60:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002e62:	00015517          	auipc	a0,0x15
    80002e66:	55e50513          	addi	a0,a0,1374 # 800183c0 <bcache>
    80002e6a:	dfdfd0ef          	jal	80000c66 <release>
}
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	64a2                	ld	s1,8(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret

0000000080002e78 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	e426                	sd	s1,8(sp)
    80002e80:	e04a                	sd	s2,0(sp)
    80002e82:	1000                	addi	s0,sp,32
    80002e84:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002e86:	00d5d59b          	srliw	a1,a1,0xd
    80002e8a:	0001e797          	auipc	a5,0x1e
    80002e8e:	c127a783          	lw	a5,-1006(a5) # 80020a9c <sb+0x1c>
    80002e92:	9dbd                	addw	a1,a1,a5
    80002e94:	dedff0ef          	jal	80002c80 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002e98:	0074f713          	andi	a4,s1,7
    80002e9c:	4785                	li	a5,1
    80002e9e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80002ea2:	14ce                	slli	s1,s1,0x33
    80002ea4:	90d9                	srli	s1,s1,0x36
    80002ea6:	00950733          	add	a4,a0,s1
    80002eaa:	05874703          	lbu	a4,88(a4)
    80002eae:	00e7f6b3          	and	a3,a5,a4
    80002eb2:	c29d                	beqz	a3,80002ed8 <bfree+0x60>
    80002eb4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002eb6:	94aa                	add	s1,s1,a0
    80002eb8:	fff7c793          	not	a5,a5
    80002ebc:	8f7d                	and	a4,a4,a5
    80002ebe:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80002ec2:	7f9000ef          	jal	80003eba <log_write>
  brelse(bp);
    80002ec6:	854a                	mv	a0,s2
    80002ec8:	ec1ff0ef          	jal	80002d88 <brelse>
}
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	64a2                	ld	s1,8(sp)
    80002ed2:	6902                	ld	s2,0(sp)
    80002ed4:	6105                	addi	sp,sp,32
    80002ed6:	8082                	ret
    panic("freeing free block");
    80002ed8:	00004517          	auipc	a0,0x4
    80002edc:	51050513          	addi	a0,a0,1296 # 800073e8 <etext+0x3e8>
    80002ee0:	901fd0ef          	jal	800007e0 <panic>

0000000080002ee4 <balloc>:
{
    80002ee4:	711d                	addi	sp,sp,-96
    80002ee6:	ec86                	sd	ra,88(sp)
    80002ee8:	e8a2                	sd	s0,80(sp)
    80002eea:	e4a6                	sd	s1,72(sp)
    80002eec:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80002eee:	0001e797          	auipc	a5,0x1e
    80002ef2:	b967a783          	lw	a5,-1130(a5) # 80020a84 <sb+0x4>
    80002ef6:	0e078f63          	beqz	a5,80002ff4 <balloc+0x110>
    80002efa:	e0ca                	sd	s2,64(sp)
    80002efc:	fc4e                	sd	s3,56(sp)
    80002efe:	f852                	sd	s4,48(sp)
    80002f00:	f456                	sd	s5,40(sp)
    80002f02:	f05a                	sd	s6,32(sp)
    80002f04:	ec5e                	sd	s7,24(sp)
    80002f06:	e862                	sd	s8,16(sp)
    80002f08:	e466                	sd	s9,8(sp)
    80002f0a:	8baa                	mv	s7,a0
    80002f0c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002f0e:	0001eb17          	auipc	s6,0x1e
    80002f12:	b72b0b13          	addi	s6,s6,-1166 # 80020a80 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f16:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80002f18:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002f1a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002f1c:	6c89                	lui	s9,0x2
    80002f1e:	a0b5                	j	80002f8a <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002f20:	97ca                	add	a5,a5,s2
    80002f22:	8e55                	or	a2,a2,a3
    80002f24:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80002f28:	854a                	mv	a0,s2
    80002f2a:	791000ef          	jal	80003eba <log_write>
        brelse(bp);
    80002f2e:	854a                	mv	a0,s2
    80002f30:	e59ff0ef          	jal	80002d88 <brelse>
  bp = bread(dev, bno);
    80002f34:	85a6                	mv	a1,s1
    80002f36:	855e                	mv	a0,s7
    80002f38:	d49ff0ef          	jal	80002c80 <bread>
    80002f3c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002f3e:	40000613          	li	a2,1024
    80002f42:	4581                	li	a1,0
    80002f44:	05850513          	addi	a0,a0,88
    80002f48:	d5bfd0ef          	jal	80000ca2 <memset>
  log_write(bp);
    80002f4c:	854a                	mv	a0,s2
    80002f4e:	76d000ef          	jal	80003eba <log_write>
  brelse(bp);
    80002f52:	854a                	mv	a0,s2
    80002f54:	e35ff0ef          	jal	80002d88 <brelse>
}
    80002f58:	6906                	ld	s2,64(sp)
    80002f5a:	79e2                	ld	s3,56(sp)
    80002f5c:	7a42                	ld	s4,48(sp)
    80002f5e:	7aa2                	ld	s5,40(sp)
    80002f60:	7b02                	ld	s6,32(sp)
    80002f62:	6be2                	ld	s7,24(sp)
    80002f64:	6c42                	ld	s8,16(sp)
    80002f66:	6ca2                	ld	s9,8(sp)
}
    80002f68:	8526                	mv	a0,s1
    80002f6a:	60e6                	ld	ra,88(sp)
    80002f6c:	6446                	ld	s0,80(sp)
    80002f6e:	64a6                	ld	s1,72(sp)
    80002f70:	6125                	addi	sp,sp,96
    80002f72:	8082                	ret
    brelse(bp);
    80002f74:	854a                	mv	a0,s2
    80002f76:	e13ff0ef          	jal	80002d88 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002f7a:	015c87bb          	addw	a5,s9,s5
    80002f7e:	00078a9b          	sext.w	s5,a5
    80002f82:	004b2703          	lw	a4,4(s6)
    80002f86:	04eaff63          	bgeu	s5,a4,80002fe4 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    80002f8a:	41fad79b          	sraiw	a5,s5,0x1f
    80002f8e:	0137d79b          	srliw	a5,a5,0x13
    80002f92:	015787bb          	addw	a5,a5,s5
    80002f96:	40d7d79b          	sraiw	a5,a5,0xd
    80002f9a:	01cb2583          	lw	a1,28(s6)
    80002f9e:	9dbd                	addw	a1,a1,a5
    80002fa0:	855e                	mv	a0,s7
    80002fa2:	cdfff0ef          	jal	80002c80 <bread>
    80002fa6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002fa8:	004b2503          	lw	a0,4(s6)
    80002fac:	000a849b          	sext.w	s1,s5
    80002fb0:	8762                	mv	a4,s8
    80002fb2:	fca4f1e3          	bgeu	s1,a0,80002f74 <balloc+0x90>
      m = 1 << (bi % 8);
    80002fb6:	00777693          	andi	a3,a4,7
    80002fba:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002fbe:	41f7579b          	sraiw	a5,a4,0x1f
    80002fc2:	01d7d79b          	srliw	a5,a5,0x1d
    80002fc6:	9fb9                	addw	a5,a5,a4
    80002fc8:	4037d79b          	sraiw	a5,a5,0x3
    80002fcc:	00f90633          	add	a2,s2,a5
    80002fd0:	05864603          	lbu	a2,88(a2)
    80002fd4:	00c6f5b3          	and	a1,a3,a2
    80002fd8:	d5a1                	beqz	a1,80002f20 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002fda:	2705                	addiw	a4,a4,1
    80002fdc:	2485                	addiw	s1,s1,1
    80002fde:	fd471ae3          	bne	a4,s4,80002fb2 <balloc+0xce>
    80002fe2:	bf49                	j	80002f74 <balloc+0x90>
    80002fe4:	6906                	ld	s2,64(sp)
    80002fe6:	79e2                	ld	s3,56(sp)
    80002fe8:	7a42                	ld	s4,48(sp)
    80002fea:	7aa2                	ld	s5,40(sp)
    80002fec:	7b02                	ld	s6,32(sp)
    80002fee:	6be2                	ld	s7,24(sp)
    80002ff0:	6c42                	ld	s8,16(sp)
    80002ff2:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80002ff4:	00004517          	auipc	a0,0x4
    80002ff8:	40c50513          	addi	a0,a0,1036 # 80007400 <etext+0x400>
    80002ffc:	cfefd0ef          	jal	800004fa <printf>
  return 0;
    80003000:	4481                	li	s1,0
    80003002:	b79d                	j	80002f68 <balloc+0x84>

0000000080003004 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003004:	7179                	addi	sp,sp,-48
    80003006:	f406                	sd	ra,40(sp)
    80003008:	f022                	sd	s0,32(sp)
    8000300a:	ec26                	sd	s1,24(sp)
    8000300c:	e84a                	sd	s2,16(sp)
    8000300e:	e44e                	sd	s3,8(sp)
    80003010:	1800                	addi	s0,sp,48
    80003012:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003014:	47ad                	li	a5,11
    80003016:	02b7e663          	bltu	a5,a1,80003042 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    8000301a:	02059793          	slli	a5,a1,0x20
    8000301e:	01e7d593          	srli	a1,a5,0x1e
    80003022:	00b504b3          	add	s1,a0,a1
    80003026:	0504a903          	lw	s2,80(s1)
    8000302a:	06091a63          	bnez	s2,8000309e <bmap+0x9a>
      addr = balloc(ip->dev);
    8000302e:	4108                	lw	a0,0(a0)
    80003030:	eb5ff0ef          	jal	80002ee4 <balloc>
    80003034:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003038:	06090363          	beqz	s2,8000309e <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    8000303c:	0524a823          	sw	s2,80(s1)
    80003040:	a8b9                	j	8000309e <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003042:	ff45849b          	addiw	s1,a1,-12
    80003046:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000304a:	0ff00793          	li	a5,255
    8000304e:	06e7ee63          	bltu	a5,a4,800030ca <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003052:	08052903          	lw	s2,128(a0)
    80003056:	00091d63          	bnez	s2,80003070 <bmap+0x6c>
      addr = balloc(ip->dev);
    8000305a:	4108                	lw	a0,0(a0)
    8000305c:	e89ff0ef          	jal	80002ee4 <balloc>
    80003060:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003064:	02090d63          	beqz	s2,8000309e <bmap+0x9a>
    80003068:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000306a:	0929a023          	sw	s2,128(s3)
    8000306e:	a011                	j	80003072 <bmap+0x6e>
    80003070:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003072:	85ca                	mv	a1,s2
    80003074:	0009a503          	lw	a0,0(s3)
    80003078:	c09ff0ef          	jal	80002c80 <bread>
    8000307c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000307e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003082:	02049713          	slli	a4,s1,0x20
    80003086:	01e75593          	srli	a1,a4,0x1e
    8000308a:	00b784b3          	add	s1,a5,a1
    8000308e:	0004a903          	lw	s2,0(s1)
    80003092:	00090e63          	beqz	s2,800030ae <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003096:	8552                	mv	a0,s4
    80003098:	cf1ff0ef          	jal	80002d88 <brelse>
    return addr;
    8000309c:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    8000309e:	854a                	mv	a0,s2
    800030a0:	70a2                	ld	ra,40(sp)
    800030a2:	7402                	ld	s0,32(sp)
    800030a4:	64e2                	ld	s1,24(sp)
    800030a6:	6942                	ld	s2,16(sp)
    800030a8:	69a2                	ld	s3,8(sp)
    800030aa:	6145                	addi	sp,sp,48
    800030ac:	8082                	ret
      addr = balloc(ip->dev);
    800030ae:	0009a503          	lw	a0,0(s3)
    800030b2:	e33ff0ef          	jal	80002ee4 <balloc>
    800030b6:	0005091b          	sext.w	s2,a0
      if(addr){
    800030ba:	fc090ee3          	beqz	s2,80003096 <bmap+0x92>
        a[bn] = addr;
    800030be:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800030c2:	8552                	mv	a0,s4
    800030c4:	5f7000ef          	jal	80003eba <log_write>
    800030c8:	b7f9                	j	80003096 <bmap+0x92>
    800030ca:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    800030cc:	00004517          	auipc	a0,0x4
    800030d0:	34c50513          	addi	a0,a0,844 # 80007418 <etext+0x418>
    800030d4:	f0cfd0ef          	jal	800007e0 <panic>

00000000800030d8 <iget>:
{
    800030d8:	7179                	addi	sp,sp,-48
    800030da:	f406                	sd	ra,40(sp)
    800030dc:	f022                	sd	s0,32(sp)
    800030de:	ec26                	sd	s1,24(sp)
    800030e0:	e84a                	sd	s2,16(sp)
    800030e2:	e44e                	sd	s3,8(sp)
    800030e4:	e052                	sd	s4,0(sp)
    800030e6:	1800                	addi	s0,sp,48
    800030e8:	89aa                	mv	s3,a0
    800030ea:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800030ec:	0001e517          	auipc	a0,0x1e
    800030f0:	9b450513          	addi	a0,a0,-1612 # 80020aa0 <itable>
    800030f4:	adbfd0ef          	jal	80000bce <acquire>
  empty = 0;
    800030f8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800030fa:	0001e497          	auipc	s1,0x1e
    800030fe:	9be48493          	addi	s1,s1,-1602 # 80020ab8 <itable+0x18>
    80003102:	0001f697          	auipc	a3,0x1f
    80003106:	44668693          	addi	a3,a3,1094 # 80022548 <log>
    8000310a:	a039                	j	80003118 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000310c:	02090963          	beqz	s2,8000313e <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003110:	08848493          	addi	s1,s1,136
    80003114:	02d48863          	beq	s1,a3,80003144 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003118:	449c                	lw	a5,8(s1)
    8000311a:	fef059e3          	blez	a5,8000310c <iget+0x34>
    8000311e:	4098                	lw	a4,0(s1)
    80003120:	ff3716e3          	bne	a4,s3,8000310c <iget+0x34>
    80003124:	40d8                	lw	a4,4(s1)
    80003126:	ff4713e3          	bne	a4,s4,8000310c <iget+0x34>
      ip->ref++;
    8000312a:	2785                	addiw	a5,a5,1
    8000312c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000312e:	0001e517          	auipc	a0,0x1e
    80003132:	97250513          	addi	a0,a0,-1678 # 80020aa0 <itable>
    80003136:	b31fd0ef          	jal	80000c66 <release>
      return ip;
    8000313a:	8926                	mv	s2,s1
    8000313c:	a02d                	j	80003166 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000313e:	fbe9                	bnez	a5,80003110 <iget+0x38>
      empty = ip;
    80003140:	8926                	mv	s2,s1
    80003142:	b7f9                	j	80003110 <iget+0x38>
  if(empty == 0)
    80003144:	02090a63          	beqz	s2,80003178 <iget+0xa0>
  ip->dev = dev;
    80003148:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000314c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003150:	4785                	li	a5,1
    80003152:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003156:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000315a:	0001e517          	auipc	a0,0x1e
    8000315e:	94650513          	addi	a0,a0,-1722 # 80020aa0 <itable>
    80003162:	b05fd0ef          	jal	80000c66 <release>
}
    80003166:	854a                	mv	a0,s2
    80003168:	70a2                	ld	ra,40(sp)
    8000316a:	7402                	ld	s0,32(sp)
    8000316c:	64e2                	ld	s1,24(sp)
    8000316e:	6942                	ld	s2,16(sp)
    80003170:	69a2                	ld	s3,8(sp)
    80003172:	6a02                	ld	s4,0(sp)
    80003174:	6145                	addi	sp,sp,48
    80003176:	8082                	ret
    panic("iget: no inodes");
    80003178:	00004517          	auipc	a0,0x4
    8000317c:	2b850513          	addi	a0,a0,696 # 80007430 <etext+0x430>
    80003180:	e60fd0ef          	jal	800007e0 <panic>

0000000080003184 <iinit>:
{
    80003184:	7179                	addi	sp,sp,-48
    80003186:	f406                	sd	ra,40(sp)
    80003188:	f022                	sd	s0,32(sp)
    8000318a:	ec26                	sd	s1,24(sp)
    8000318c:	e84a                	sd	s2,16(sp)
    8000318e:	e44e                	sd	s3,8(sp)
    80003190:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003192:	00004597          	auipc	a1,0x4
    80003196:	2ae58593          	addi	a1,a1,686 # 80007440 <etext+0x440>
    8000319a:	0001e517          	auipc	a0,0x1e
    8000319e:	90650513          	addi	a0,a0,-1786 # 80020aa0 <itable>
    800031a2:	9adfd0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    800031a6:	0001e497          	auipc	s1,0x1e
    800031aa:	92248493          	addi	s1,s1,-1758 # 80020ac8 <itable+0x28>
    800031ae:	0001f997          	auipc	s3,0x1f
    800031b2:	3aa98993          	addi	s3,s3,938 # 80022558 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800031b6:	00004917          	auipc	s2,0x4
    800031ba:	29290913          	addi	s2,s2,658 # 80007448 <etext+0x448>
    800031be:	85ca                	mv	a1,s2
    800031c0:	8526                	mv	a0,s1
    800031c2:	5bb000ef          	jal	80003f7c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800031c6:	08848493          	addi	s1,s1,136
    800031ca:	ff349ae3          	bne	s1,s3,800031be <iinit+0x3a>
}
    800031ce:	70a2                	ld	ra,40(sp)
    800031d0:	7402                	ld	s0,32(sp)
    800031d2:	64e2                	ld	s1,24(sp)
    800031d4:	6942                	ld	s2,16(sp)
    800031d6:	69a2                	ld	s3,8(sp)
    800031d8:	6145                	addi	sp,sp,48
    800031da:	8082                	ret

00000000800031dc <ialloc>:
{
    800031dc:	7139                	addi	sp,sp,-64
    800031de:	fc06                	sd	ra,56(sp)
    800031e0:	f822                	sd	s0,48(sp)
    800031e2:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800031e4:	0001e717          	auipc	a4,0x1e
    800031e8:	8a872703          	lw	a4,-1880(a4) # 80020a8c <sb+0xc>
    800031ec:	4785                	li	a5,1
    800031ee:	06e7f063          	bgeu	a5,a4,8000324e <ialloc+0x72>
    800031f2:	f426                	sd	s1,40(sp)
    800031f4:	f04a                	sd	s2,32(sp)
    800031f6:	ec4e                	sd	s3,24(sp)
    800031f8:	e852                	sd	s4,16(sp)
    800031fa:	e456                	sd	s5,8(sp)
    800031fc:	e05a                	sd	s6,0(sp)
    800031fe:	8aaa                	mv	s5,a0
    80003200:	8b2e                	mv	s6,a1
    80003202:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003204:	0001ea17          	auipc	s4,0x1e
    80003208:	87ca0a13          	addi	s4,s4,-1924 # 80020a80 <sb>
    8000320c:	00495593          	srli	a1,s2,0x4
    80003210:	018a2783          	lw	a5,24(s4)
    80003214:	9dbd                	addw	a1,a1,a5
    80003216:	8556                	mv	a0,s5
    80003218:	a69ff0ef          	jal	80002c80 <bread>
    8000321c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000321e:	05850993          	addi	s3,a0,88
    80003222:	00f97793          	andi	a5,s2,15
    80003226:	079a                	slli	a5,a5,0x6
    80003228:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000322a:	00099783          	lh	a5,0(s3)
    8000322e:	cb9d                	beqz	a5,80003264 <ialloc+0x88>
    brelse(bp);
    80003230:	b59ff0ef          	jal	80002d88 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003234:	0905                	addi	s2,s2,1
    80003236:	00ca2703          	lw	a4,12(s4)
    8000323a:	0009079b          	sext.w	a5,s2
    8000323e:	fce7e7e3          	bltu	a5,a4,8000320c <ialloc+0x30>
    80003242:	74a2                	ld	s1,40(sp)
    80003244:	7902                	ld	s2,32(sp)
    80003246:	69e2                	ld	s3,24(sp)
    80003248:	6a42                	ld	s4,16(sp)
    8000324a:	6aa2                	ld	s5,8(sp)
    8000324c:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    8000324e:	00004517          	auipc	a0,0x4
    80003252:	20250513          	addi	a0,a0,514 # 80007450 <etext+0x450>
    80003256:	aa4fd0ef          	jal	800004fa <printf>
  return 0;
    8000325a:	4501                	li	a0,0
}
    8000325c:	70e2                	ld	ra,56(sp)
    8000325e:	7442                	ld	s0,48(sp)
    80003260:	6121                	addi	sp,sp,64
    80003262:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003264:	04000613          	li	a2,64
    80003268:	4581                	li	a1,0
    8000326a:	854e                	mv	a0,s3
    8000326c:	a37fd0ef          	jal	80000ca2 <memset>
      dip->type = type;
    80003270:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003274:	8526                	mv	a0,s1
    80003276:	445000ef          	jal	80003eba <log_write>
      brelse(bp);
    8000327a:	8526                	mv	a0,s1
    8000327c:	b0dff0ef          	jal	80002d88 <brelse>
      return iget(dev, inum);
    80003280:	0009059b          	sext.w	a1,s2
    80003284:	8556                	mv	a0,s5
    80003286:	e53ff0ef          	jal	800030d8 <iget>
    8000328a:	74a2                	ld	s1,40(sp)
    8000328c:	7902                	ld	s2,32(sp)
    8000328e:	69e2                	ld	s3,24(sp)
    80003290:	6a42                	ld	s4,16(sp)
    80003292:	6aa2                	ld	s5,8(sp)
    80003294:	6b02                	ld	s6,0(sp)
    80003296:	b7d9                	j	8000325c <ialloc+0x80>

0000000080003298 <iupdate>:
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	e426                	sd	s1,8(sp)
    800032a0:	e04a                	sd	s2,0(sp)
    800032a2:	1000                	addi	s0,sp,32
    800032a4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800032a6:	415c                	lw	a5,4(a0)
    800032a8:	0047d79b          	srliw	a5,a5,0x4
    800032ac:	0001d597          	auipc	a1,0x1d
    800032b0:	7ec5a583          	lw	a1,2028(a1) # 80020a98 <sb+0x18>
    800032b4:	9dbd                	addw	a1,a1,a5
    800032b6:	4108                	lw	a0,0(a0)
    800032b8:	9c9ff0ef          	jal	80002c80 <bread>
    800032bc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800032be:	05850793          	addi	a5,a0,88
    800032c2:	40d8                	lw	a4,4(s1)
    800032c4:	8b3d                	andi	a4,a4,15
    800032c6:	071a                	slli	a4,a4,0x6
    800032c8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800032ca:	04449703          	lh	a4,68(s1)
    800032ce:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800032d2:	04649703          	lh	a4,70(s1)
    800032d6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800032da:	04849703          	lh	a4,72(s1)
    800032de:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800032e2:	04a49703          	lh	a4,74(s1)
    800032e6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800032ea:	44f8                	lw	a4,76(s1)
    800032ec:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800032ee:	03400613          	li	a2,52
    800032f2:	05048593          	addi	a1,s1,80
    800032f6:	00c78513          	addi	a0,a5,12
    800032fa:	a05fd0ef          	jal	80000cfe <memmove>
  log_write(bp);
    800032fe:	854a                	mv	a0,s2
    80003300:	3bb000ef          	jal	80003eba <log_write>
  brelse(bp);
    80003304:	854a                	mv	a0,s2
    80003306:	a83ff0ef          	jal	80002d88 <brelse>
}
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	64a2                	ld	s1,8(sp)
    80003310:	6902                	ld	s2,0(sp)
    80003312:	6105                	addi	sp,sp,32
    80003314:	8082                	ret

0000000080003316 <idup>:
{
    80003316:	1101                	addi	sp,sp,-32
    80003318:	ec06                	sd	ra,24(sp)
    8000331a:	e822                	sd	s0,16(sp)
    8000331c:	e426                	sd	s1,8(sp)
    8000331e:	1000                	addi	s0,sp,32
    80003320:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003322:	0001d517          	auipc	a0,0x1d
    80003326:	77e50513          	addi	a0,a0,1918 # 80020aa0 <itable>
    8000332a:	8a5fd0ef          	jal	80000bce <acquire>
  ip->ref++;
    8000332e:	449c                	lw	a5,8(s1)
    80003330:	2785                	addiw	a5,a5,1
    80003332:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003334:	0001d517          	auipc	a0,0x1d
    80003338:	76c50513          	addi	a0,a0,1900 # 80020aa0 <itable>
    8000333c:	92bfd0ef          	jal	80000c66 <release>
}
    80003340:	8526                	mv	a0,s1
    80003342:	60e2                	ld	ra,24(sp)
    80003344:	6442                	ld	s0,16(sp)
    80003346:	64a2                	ld	s1,8(sp)
    80003348:	6105                	addi	sp,sp,32
    8000334a:	8082                	ret

000000008000334c <ilock>:
{
    8000334c:	1101                	addi	sp,sp,-32
    8000334e:	ec06                	sd	ra,24(sp)
    80003350:	e822                	sd	s0,16(sp)
    80003352:	e426                	sd	s1,8(sp)
    80003354:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003356:	cd19                	beqz	a0,80003374 <ilock+0x28>
    80003358:	84aa                	mv	s1,a0
    8000335a:	451c                	lw	a5,8(a0)
    8000335c:	00f05c63          	blez	a5,80003374 <ilock+0x28>
  acquiresleep(&ip->lock);
    80003360:	0541                	addi	a0,a0,16
    80003362:	451000ef          	jal	80003fb2 <acquiresleep>
  if(ip->valid == 0){
    80003366:	40bc                	lw	a5,64(s1)
    80003368:	cf89                	beqz	a5,80003382 <ilock+0x36>
}
    8000336a:	60e2                	ld	ra,24(sp)
    8000336c:	6442                	ld	s0,16(sp)
    8000336e:	64a2                	ld	s1,8(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret
    80003374:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003376:	00004517          	auipc	a0,0x4
    8000337a:	0f250513          	addi	a0,a0,242 # 80007468 <etext+0x468>
    8000337e:	c62fd0ef          	jal	800007e0 <panic>
    80003382:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003384:	40dc                	lw	a5,4(s1)
    80003386:	0047d79b          	srliw	a5,a5,0x4
    8000338a:	0001d597          	auipc	a1,0x1d
    8000338e:	70e5a583          	lw	a1,1806(a1) # 80020a98 <sb+0x18>
    80003392:	9dbd                	addw	a1,a1,a5
    80003394:	4088                	lw	a0,0(s1)
    80003396:	8ebff0ef          	jal	80002c80 <bread>
    8000339a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000339c:	05850593          	addi	a1,a0,88
    800033a0:	40dc                	lw	a5,4(s1)
    800033a2:	8bbd                	andi	a5,a5,15
    800033a4:	079a                	slli	a5,a5,0x6
    800033a6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800033a8:	00059783          	lh	a5,0(a1)
    800033ac:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800033b0:	00259783          	lh	a5,2(a1)
    800033b4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800033b8:	00459783          	lh	a5,4(a1)
    800033bc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800033c0:	00659783          	lh	a5,6(a1)
    800033c4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800033c8:	459c                	lw	a5,8(a1)
    800033ca:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800033cc:	03400613          	li	a2,52
    800033d0:	05b1                	addi	a1,a1,12
    800033d2:	05048513          	addi	a0,s1,80
    800033d6:	929fd0ef          	jal	80000cfe <memmove>
    brelse(bp);
    800033da:	854a                	mv	a0,s2
    800033dc:	9adff0ef          	jal	80002d88 <brelse>
    ip->valid = 1;
    800033e0:	4785                	li	a5,1
    800033e2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800033e4:	04449783          	lh	a5,68(s1)
    800033e8:	c399                	beqz	a5,800033ee <ilock+0xa2>
    800033ea:	6902                	ld	s2,0(sp)
    800033ec:	bfbd                	j	8000336a <ilock+0x1e>
      panic("ilock: no type");
    800033ee:	00004517          	auipc	a0,0x4
    800033f2:	08250513          	addi	a0,a0,130 # 80007470 <etext+0x470>
    800033f6:	beafd0ef          	jal	800007e0 <panic>

00000000800033fa <iunlock>:
{
    800033fa:	1101                	addi	sp,sp,-32
    800033fc:	ec06                	sd	ra,24(sp)
    800033fe:	e822                	sd	s0,16(sp)
    80003400:	e426                	sd	s1,8(sp)
    80003402:	e04a                	sd	s2,0(sp)
    80003404:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003406:	c505                	beqz	a0,8000342e <iunlock+0x34>
    80003408:	84aa                	mv	s1,a0
    8000340a:	01050913          	addi	s2,a0,16
    8000340e:	854a                	mv	a0,s2
    80003410:	421000ef          	jal	80004030 <holdingsleep>
    80003414:	cd09                	beqz	a0,8000342e <iunlock+0x34>
    80003416:	449c                	lw	a5,8(s1)
    80003418:	00f05b63          	blez	a5,8000342e <iunlock+0x34>
  releasesleep(&ip->lock);
    8000341c:	854a                	mv	a0,s2
    8000341e:	3db000ef          	jal	80003ff8 <releasesleep>
}
    80003422:	60e2                	ld	ra,24(sp)
    80003424:	6442                	ld	s0,16(sp)
    80003426:	64a2                	ld	s1,8(sp)
    80003428:	6902                	ld	s2,0(sp)
    8000342a:	6105                	addi	sp,sp,32
    8000342c:	8082                	ret
    panic("iunlock");
    8000342e:	00004517          	auipc	a0,0x4
    80003432:	05250513          	addi	a0,a0,82 # 80007480 <etext+0x480>
    80003436:	baafd0ef          	jal	800007e0 <panic>

000000008000343a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	e84a                	sd	s2,16(sp)
    80003444:	e44e                	sd	s3,8(sp)
    80003446:	1800                	addi	s0,sp,48
    80003448:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000344a:	05050493          	addi	s1,a0,80
    8000344e:	08050913          	addi	s2,a0,128
    80003452:	a021                	j	8000345a <itrunc+0x20>
    80003454:	0491                	addi	s1,s1,4
    80003456:	01248b63          	beq	s1,s2,8000346c <itrunc+0x32>
    if(ip->addrs[i]){
    8000345a:	408c                	lw	a1,0(s1)
    8000345c:	dde5                	beqz	a1,80003454 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    8000345e:	0009a503          	lw	a0,0(s3)
    80003462:	a17ff0ef          	jal	80002e78 <bfree>
      ip->addrs[i] = 0;
    80003466:	0004a023          	sw	zero,0(s1)
    8000346a:	b7ed                	j	80003454 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000346c:	0809a583          	lw	a1,128(s3)
    80003470:	ed89                	bnez	a1,8000348a <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003472:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003476:	854e                	mv	a0,s3
    80003478:	e21ff0ef          	jal	80003298 <iupdate>
}
    8000347c:	70a2                	ld	ra,40(sp)
    8000347e:	7402                	ld	s0,32(sp)
    80003480:	64e2                	ld	s1,24(sp)
    80003482:	6942                	ld	s2,16(sp)
    80003484:	69a2                	ld	s3,8(sp)
    80003486:	6145                	addi	sp,sp,48
    80003488:	8082                	ret
    8000348a:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000348c:	0009a503          	lw	a0,0(s3)
    80003490:	ff0ff0ef          	jal	80002c80 <bread>
    80003494:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003496:	05850493          	addi	s1,a0,88
    8000349a:	45850913          	addi	s2,a0,1112
    8000349e:	a021                	j	800034a6 <itrunc+0x6c>
    800034a0:	0491                	addi	s1,s1,4
    800034a2:	01248963          	beq	s1,s2,800034b4 <itrunc+0x7a>
      if(a[j])
    800034a6:	408c                	lw	a1,0(s1)
    800034a8:	dde5                	beqz	a1,800034a0 <itrunc+0x66>
        bfree(ip->dev, a[j]);
    800034aa:	0009a503          	lw	a0,0(s3)
    800034ae:	9cbff0ef          	jal	80002e78 <bfree>
    800034b2:	b7fd                	j	800034a0 <itrunc+0x66>
    brelse(bp);
    800034b4:	8552                	mv	a0,s4
    800034b6:	8d3ff0ef          	jal	80002d88 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800034ba:	0809a583          	lw	a1,128(s3)
    800034be:	0009a503          	lw	a0,0(s3)
    800034c2:	9b7ff0ef          	jal	80002e78 <bfree>
    ip->addrs[NDIRECT] = 0;
    800034c6:	0809a023          	sw	zero,128(s3)
    800034ca:	6a02                	ld	s4,0(sp)
    800034cc:	b75d                	j	80003472 <itrunc+0x38>

00000000800034ce <iput>:
{
    800034ce:	1101                	addi	sp,sp,-32
    800034d0:	ec06                	sd	ra,24(sp)
    800034d2:	e822                	sd	s0,16(sp)
    800034d4:	e426                	sd	s1,8(sp)
    800034d6:	1000                	addi	s0,sp,32
    800034d8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800034da:	0001d517          	auipc	a0,0x1d
    800034de:	5c650513          	addi	a0,a0,1478 # 80020aa0 <itable>
    800034e2:	eecfd0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800034e6:	4498                	lw	a4,8(s1)
    800034e8:	4785                	li	a5,1
    800034ea:	02f70063          	beq	a4,a5,8000350a <iput+0x3c>
  ip->ref--;
    800034ee:	449c                	lw	a5,8(s1)
    800034f0:	37fd                	addiw	a5,a5,-1
    800034f2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800034f4:	0001d517          	auipc	a0,0x1d
    800034f8:	5ac50513          	addi	a0,a0,1452 # 80020aa0 <itable>
    800034fc:	f6afd0ef          	jal	80000c66 <release>
}
    80003500:	60e2                	ld	ra,24(sp)
    80003502:	6442                	ld	s0,16(sp)
    80003504:	64a2                	ld	s1,8(sp)
    80003506:	6105                	addi	sp,sp,32
    80003508:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000350a:	40bc                	lw	a5,64(s1)
    8000350c:	d3ed                	beqz	a5,800034ee <iput+0x20>
    8000350e:	04a49783          	lh	a5,74(s1)
    80003512:	fff1                	bnez	a5,800034ee <iput+0x20>
    80003514:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003516:	01048913          	addi	s2,s1,16
    8000351a:	854a                	mv	a0,s2
    8000351c:	297000ef          	jal	80003fb2 <acquiresleep>
    release(&itable.lock);
    80003520:	0001d517          	auipc	a0,0x1d
    80003524:	58050513          	addi	a0,a0,1408 # 80020aa0 <itable>
    80003528:	f3efd0ef          	jal	80000c66 <release>
    itrunc(ip);
    8000352c:	8526                	mv	a0,s1
    8000352e:	f0dff0ef          	jal	8000343a <itrunc>
    ip->type = 0;
    80003532:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003536:	8526                	mv	a0,s1
    80003538:	d61ff0ef          	jal	80003298 <iupdate>
    ip->valid = 0;
    8000353c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003540:	854a                	mv	a0,s2
    80003542:	2b7000ef          	jal	80003ff8 <releasesleep>
    acquire(&itable.lock);
    80003546:	0001d517          	auipc	a0,0x1d
    8000354a:	55a50513          	addi	a0,a0,1370 # 80020aa0 <itable>
    8000354e:	e80fd0ef          	jal	80000bce <acquire>
    80003552:	6902                	ld	s2,0(sp)
    80003554:	bf69                	j	800034ee <iput+0x20>

0000000080003556 <iunlockput>:
{
    80003556:	1101                	addi	sp,sp,-32
    80003558:	ec06                	sd	ra,24(sp)
    8000355a:	e822                	sd	s0,16(sp)
    8000355c:	e426                	sd	s1,8(sp)
    8000355e:	1000                	addi	s0,sp,32
    80003560:	84aa                	mv	s1,a0
  iunlock(ip);
    80003562:	e99ff0ef          	jal	800033fa <iunlock>
  iput(ip);
    80003566:	8526                	mv	a0,s1
    80003568:	f67ff0ef          	jal	800034ce <iput>
}
    8000356c:	60e2                	ld	ra,24(sp)
    8000356e:	6442                	ld	s0,16(sp)
    80003570:	64a2                	ld	s1,8(sp)
    80003572:	6105                	addi	sp,sp,32
    80003574:	8082                	ret

0000000080003576 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003576:	0001d717          	auipc	a4,0x1d
    8000357a:	51672703          	lw	a4,1302(a4) # 80020a8c <sb+0xc>
    8000357e:	4785                	li	a5,1
    80003580:	0ae7ff63          	bgeu	a5,a4,8000363e <ireclaim+0xc8>
{
    80003584:	7139                	addi	sp,sp,-64
    80003586:	fc06                	sd	ra,56(sp)
    80003588:	f822                	sd	s0,48(sp)
    8000358a:	f426                	sd	s1,40(sp)
    8000358c:	f04a                	sd	s2,32(sp)
    8000358e:	ec4e                	sd	s3,24(sp)
    80003590:	e852                	sd	s4,16(sp)
    80003592:	e456                	sd	s5,8(sp)
    80003594:	e05a                	sd	s6,0(sp)
    80003596:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003598:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    8000359a:	00050a1b          	sext.w	s4,a0
    8000359e:	0001da97          	auipc	s5,0x1d
    800035a2:	4e2a8a93          	addi	s5,s5,1250 # 80020a80 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    800035a6:	00004b17          	auipc	s6,0x4
    800035aa:	ee2b0b13          	addi	s6,s6,-286 # 80007488 <etext+0x488>
    800035ae:	a099                	j	800035f4 <ireclaim+0x7e>
    800035b0:	85ce                	mv	a1,s3
    800035b2:	855a                	mv	a0,s6
    800035b4:	f47fc0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    800035b8:	85ce                	mv	a1,s3
    800035ba:	8552                	mv	a0,s4
    800035bc:	b1dff0ef          	jal	800030d8 <iget>
    800035c0:	89aa                	mv	s3,a0
    brelse(bp);
    800035c2:	854a                	mv	a0,s2
    800035c4:	fc4ff0ef          	jal	80002d88 <brelse>
    if (ip) {
    800035c8:	00098f63          	beqz	s3,800035e6 <ireclaim+0x70>
      begin_op();
    800035cc:	76a000ef          	jal	80003d36 <begin_op>
      ilock(ip);
    800035d0:	854e                	mv	a0,s3
    800035d2:	d7bff0ef          	jal	8000334c <ilock>
      iunlock(ip);
    800035d6:	854e                	mv	a0,s3
    800035d8:	e23ff0ef          	jal	800033fa <iunlock>
      iput(ip);
    800035dc:	854e                	mv	a0,s3
    800035de:	ef1ff0ef          	jal	800034ce <iput>
      end_op();
    800035e2:	7be000ef          	jal	80003da0 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800035e6:	0485                	addi	s1,s1,1
    800035e8:	00caa703          	lw	a4,12(s5)
    800035ec:	0004879b          	sext.w	a5,s1
    800035f0:	02e7fd63          	bgeu	a5,a4,8000362a <ireclaim+0xb4>
    800035f4:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800035f8:	0044d593          	srli	a1,s1,0x4
    800035fc:	018aa783          	lw	a5,24(s5)
    80003600:	9dbd                	addw	a1,a1,a5
    80003602:	8552                	mv	a0,s4
    80003604:	e7cff0ef          	jal	80002c80 <bread>
    80003608:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    8000360a:	05850793          	addi	a5,a0,88
    8000360e:	00f9f713          	andi	a4,s3,15
    80003612:	071a                	slli	a4,a4,0x6
    80003614:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003616:	00079703          	lh	a4,0(a5)
    8000361a:	c701                	beqz	a4,80003622 <ireclaim+0xac>
    8000361c:	00679783          	lh	a5,6(a5)
    80003620:	dbc1                	beqz	a5,800035b0 <ireclaim+0x3a>
    brelse(bp);
    80003622:	854a                	mv	a0,s2
    80003624:	f64ff0ef          	jal	80002d88 <brelse>
    if (ip) {
    80003628:	bf7d                	j	800035e6 <ireclaim+0x70>
}
    8000362a:	70e2                	ld	ra,56(sp)
    8000362c:	7442                	ld	s0,48(sp)
    8000362e:	74a2                	ld	s1,40(sp)
    80003630:	7902                	ld	s2,32(sp)
    80003632:	69e2                	ld	s3,24(sp)
    80003634:	6a42                	ld	s4,16(sp)
    80003636:	6aa2                	ld	s5,8(sp)
    80003638:	6b02                	ld	s6,0(sp)
    8000363a:	6121                	addi	sp,sp,64
    8000363c:	8082                	ret
    8000363e:	8082                	ret

0000000080003640 <fsinit>:
fsinit(int dev) {
    80003640:	7179                	addi	sp,sp,-48
    80003642:	f406                	sd	ra,40(sp)
    80003644:	f022                	sd	s0,32(sp)
    80003646:	ec26                	sd	s1,24(sp)
    80003648:	e84a                	sd	s2,16(sp)
    8000364a:	e44e                	sd	s3,8(sp)
    8000364c:	1800                	addi	s0,sp,48
    8000364e:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    80003650:	4585                	li	a1,1
    80003652:	e2eff0ef          	jal	80002c80 <bread>
    80003656:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003658:	0001d997          	auipc	s3,0x1d
    8000365c:	42898993          	addi	s3,s3,1064 # 80020a80 <sb>
    80003660:	02000613          	li	a2,32
    80003664:	05850593          	addi	a1,a0,88
    80003668:	854e                	mv	a0,s3
    8000366a:	e94fd0ef          	jal	80000cfe <memmove>
  brelse(bp);
    8000366e:	854a                	mv	a0,s2
    80003670:	f18ff0ef          	jal	80002d88 <brelse>
  if(sb.magic != FSMAGIC)
    80003674:	0009a703          	lw	a4,0(s3)
    80003678:	102037b7          	lui	a5,0x10203
    8000367c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003680:	02f71363          	bne	a4,a5,800036a6 <fsinit+0x66>
  initlog(dev, &sb);
    80003684:	0001d597          	auipc	a1,0x1d
    80003688:	3fc58593          	addi	a1,a1,1020 # 80020a80 <sb>
    8000368c:	8526                	mv	a0,s1
    8000368e:	62a000ef          	jal	80003cb8 <initlog>
  ireclaim(dev);
    80003692:	8526                	mv	a0,s1
    80003694:	ee3ff0ef          	jal	80003576 <ireclaim>
}
    80003698:	70a2                	ld	ra,40(sp)
    8000369a:	7402                	ld	s0,32(sp)
    8000369c:	64e2                	ld	s1,24(sp)
    8000369e:	6942                	ld	s2,16(sp)
    800036a0:	69a2                	ld	s3,8(sp)
    800036a2:	6145                	addi	sp,sp,48
    800036a4:	8082                	ret
    panic("invalid file system");
    800036a6:	00004517          	auipc	a0,0x4
    800036aa:	e0250513          	addi	a0,a0,-510 # 800074a8 <etext+0x4a8>
    800036ae:	932fd0ef          	jal	800007e0 <panic>

00000000800036b2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800036b2:	1141                	addi	sp,sp,-16
    800036b4:	e422                	sd	s0,8(sp)
    800036b6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800036b8:	411c                	lw	a5,0(a0)
    800036ba:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800036bc:	415c                	lw	a5,4(a0)
    800036be:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800036c0:	04451783          	lh	a5,68(a0)
    800036c4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800036c8:	04a51783          	lh	a5,74(a0)
    800036cc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800036d0:	04c56783          	lwu	a5,76(a0)
    800036d4:	e99c                	sd	a5,16(a1)
}
    800036d6:	6422                	ld	s0,8(sp)
    800036d8:	0141                	addi	sp,sp,16
    800036da:	8082                	ret

00000000800036dc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800036dc:	457c                	lw	a5,76(a0)
    800036de:	0ed7eb63          	bltu	a5,a3,800037d4 <readi+0xf8>
{
    800036e2:	7159                	addi	sp,sp,-112
    800036e4:	f486                	sd	ra,104(sp)
    800036e6:	f0a2                	sd	s0,96(sp)
    800036e8:	eca6                	sd	s1,88(sp)
    800036ea:	e0d2                	sd	s4,64(sp)
    800036ec:	fc56                	sd	s5,56(sp)
    800036ee:	f85a                	sd	s6,48(sp)
    800036f0:	f45e                	sd	s7,40(sp)
    800036f2:	1880                	addi	s0,sp,112
    800036f4:	8b2a                	mv	s6,a0
    800036f6:	8bae                	mv	s7,a1
    800036f8:	8a32                	mv	s4,a2
    800036fa:	84b6                	mv	s1,a3
    800036fc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800036fe:	9f35                	addw	a4,a4,a3
    return 0;
    80003700:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003702:	0cd76063          	bltu	a4,a3,800037c2 <readi+0xe6>
    80003706:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003708:	00e7f463          	bgeu	a5,a4,80003710 <readi+0x34>
    n = ip->size - off;
    8000370c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003710:	080a8f63          	beqz	s5,800037ae <readi+0xd2>
    80003714:	e8ca                	sd	s2,80(sp)
    80003716:	f062                	sd	s8,32(sp)
    80003718:	ec66                	sd	s9,24(sp)
    8000371a:	e86a                	sd	s10,16(sp)
    8000371c:	e46e                	sd	s11,8(sp)
    8000371e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003720:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003724:	5c7d                	li	s8,-1
    80003726:	a80d                	j	80003758 <readi+0x7c>
    80003728:	020d1d93          	slli	s11,s10,0x20
    8000372c:	020ddd93          	srli	s11,s11,0x20
    80003730:	05890613          	addi	a2,s2,88
    80003734:	86ee                	mv	a3,s11
    80003736:	963a                	add	a2,a2,a4
    80003738:	85d2                	mv	a1,s4
    8000373a:	855e                	mv	a0,s7
    8000373c:	b5bfe0ef          	jal	80002296 <either_copyout>
    80003740:	05850763          	beq	a0,s8,8000378e <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003744:	854a                	mv	a0,s2
    80003746:	e42ff0ef          	jal	80002d88 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000374a:	013d09bb          	addw	s3,s10,s3
    8000374e:	009d04bb          	addw	s1,s10,s1
    80003752:	9a6e                	add	s4,s4,s11
    80003754:	0559f763          	bgeu	s3,s5,800037a2 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    80003758:	00a4d59b          	srliw	a1,s1,0xa
    8000375c:	855a                	mv	a0,s6
    8000375e:	8a7ff0ef          	jal	80003004 <bmap>
    80003762:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003766:	c5b1                	beqz	a1,800037b2 <readi+0xd6>
    bp = bread(ip->dev, addr);
    80003768:	000b2503          	lw	a0,0(s6)
    8000376c:	d14ff0ef          	jal	80002c80 <bread>
    80003770:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003772:	3ff4f713          	andi	a4,s1,1023
    80003776:	40ec87bb          	subw	a5,s9,a4
    8000377a:	413a86bb          	subw	a3,s5,s3
    8000377e:	8d3e                	mv	s10,a5
    80003780:	2781                	sext.w	a5,a5
    80003782:	0006861b          	sext.w	a2,a3
    80003786:	faf671e3          	bgeu	a2,a5,80003728 <readi+0x4c>
    8000378a:	8d36                	mv	s10,a3
    8000378c:	bf71                	j	80003728 <readi+0x4c>
      brelse(bp);
    8000378e:	854a                	mv	a0,s2
    80003790:	df8ff0ef          	jal	80002d88 <brelse>
      tot = -1;
    80003794:	59fd                	li	s3,-1
      break;
    80003796:	6946                	ld	s2,80(sp)
    80003798:	7c02                	ld	s8,32(sp)
    8000379a:	6ce2                	ld	s9,24(sp)
    8000379c:	6d42                	ld	s10,16(sp)
    8000379e:	6da2                	ld	s11,8(sp)
    800037a0:	a831                	j	800037bc <readi+0xe0>
    800037a2:	6946                	ld	s2,80(sp)
    800037a4:	7c02                	ld	s8,32(sp)
    800037a6:	6ce2                	ld	s9,24(sp)
    800037a8:	6d42                	ld	s10,16(sp)
    800037aa:	6da2                	ld	s11,8(sp)
    800037ac:	a801                	j	800037bc <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800037ae:	89d6                	mv	s3,s5
    800037b0:	a031                	j	800037bc <readi+0xe0>
    800037b2:	6946                	ld	s2,80(sp)
    800037b4:	7c02                	ld	s8,32(sp)
    800037b6:	6ce2                	ld	s9,24(sp)
    800037b8:	6d42                	ld	s10,16(sp)
    800037ba:	6da2                	ld	s11,8(sp)
  }
  return tot;
    800037bc:	0009851b          	sext.w	a0,s3
    800037c0:	69a6                	ld	s3,72(sp)
}
    800037c2:	70a6                	ld	ra,104(sp)
    800037c4:	7406                	ld	s0,96(sp)
    800037c6:	64e6                	ld	s1,88(sp)
    800037c8:	6a06                	ld	s4,64(sp)
    800037ca:	7ae2                	ld	s5,56(sp)
    800037cc:	7b42                	ld	s6,48(sp)
    800037ce:	7ba2                	ld	s7,40(sp)
    800037d0:	6165                	addi	sp,sp,112
    800037d2:	8082                	ret
    return 0;
    800037d4:	4501                	li	a0,0
}
    800037d6:	8082                	ret

00000000800037d8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800037d8:	457c                	lw	a5,76(a0)
    800037da:	10d7e063          	bltu	a5,a3,800038da <writei+0x102>
{
    800037de:	7159                	addi	sp,sp,-112
    800037e0:	f486                	sd	ra,104(sp)
    800037e2:	f0a2                	sd	s0,96(sp)
    800037e4:	e8ca                	sd	s2,80(sp)
    800037e6:	e0d2                	sd	s4,64(sp)
    800037e8:	fc56                	sd	s5,56(sp)
    800037ea:	f85a                	sd	s6,48(sp)
    800037ec:	f45e                	sd	s7,40(sp)
    800037ee:	1880                	addi	s0,sp,112
    800037f0:	8aaa                	mv	s5,a0
    800037f2:	8bae                	mv	s7,a1
    800037f4:	8a32                	mv	s4,a2
    800037f6:	8936                	mv	s2,a3
    800037f8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800037fa:	00e687bb          	addw	a5,a3,a4
    800037fe:	0ed7e063          	bltu	a5,a3,800038de <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003802:	00043737          	lui	a4,0x43
    80003806:	0cf76e63          	bltu	a4,a5,800038e2 <writei+0x10a>
    8000380a:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000380c:	0a0b0f63          	beqz	s6,800038ca <writei+0xf2>
    80003810:	eca6                	sd	s1,88(sp)
    80003812:	f062                	sd	s8,32(sp)
    80003814:	ec66                	sd	s9,24(sp)
    80003816:	e86a                	sd	s10,16(sp)
    80003818:	e46e                	sd	s11,8(sp)
    8000381a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000381c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003820:	5c7d                	li	s8,-1
    80003822:	a825                	j	8000385a <writei+0x82>
    80003824:	020d1d93          	slli	s11,s10,0x20
    80003828:	020ddd93          	srli	s11,s11,0x20
    8000382c:	05848513          	addi	a0,s1,88
    80003830:	86ee                	mv	a3,s11
    80003832:	8652                	mv	a2,s4
    80003834:	85de                	mv	a1,s7
    80003836:	953a                	add	a0,a0,a4
    80003838:	aa9fe0ef          	jal	800022e0 <either_copyin>
    8000383c:	05850a63          	beq	a0,s8,80003890 <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003840:	8526                	mv	a0,s1
    80003842:	678000ef          	jal	80003eba <log_write>
    brelse(bp);
    80003846:	8526                	mv	a0,s1
    80003848:	d40ff0ef          	jal	80002d88 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000384c:	013d09bb          	addw	s3,s10,s3
    80003850:	012d093b          	addw	s2,s10,s2
    80003854:	9a6e                	add	s4,s4,s11
    80003856:	0569f063          	bgeu	s3,s6,80003896 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    8000385a:	00a9559b          	srliw	a1,s2,0xa
    8000385e:	8556                	mv	a0,s5
    80003860:	fa4ff0ef          	jal	80003004 <bmap>
    80003864:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003868:	c59d                	beqz	a1,80003896 <writei+0xbe>
    bp = bread(ip->dev, addr);
    8000386a:	000aa503          	lw	a0,0(s5)
    8000386e:	c12ff0ef          	jal	80002c80 <bread>
    80003872:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003874:	3ff97713          	andi	a4,s2,1023
    80003878:	40ec87bb          	subw	a5,s9,a4
    8000387c:	413b06bb          	subw	a3,s6,s3
    80003880:	8d3e                	mv	s10,a5
    80003882:	2781                	sext.w	a5,a5
    80003884:	0006861b          	sext.w	a2,a3
    80003888:	f8f67ee3          	bgeu	a2,a5,80003824 <writei+0x4c>
    8000388c:	8d36                	mv	s10,a3
    8000388e:	bf59                	j	80003824 <writei+0x4c>
      brelse(bp);
    80003890:	8526                	mv	a0,s1
    80003892:	cf6ff0ef          	jal	80002d88 <brelse>
  }

  if(off > ip->size)
    80003896:	04caa783          	lw	a5,76(s5)
    8000389a:	0327fa63          	bgeu	a5,s2,800038ce <writei+0xf6>
    ip->size = off;
    8000389e:	052aa623          	sw	s2,76(s5)
    800038a2:	64e6                	ld	s1,88(sp)
    800038a4:	7c02                	ld	s8,32(sp)
    800038a6:	6ce2                	ld	s9,24(sp)
    800038a8:	6d42                	ld	s10,16(sp)
    800038aa:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800038ac:	8556                	mv	a0,s5
    800038ae:	9ebff0ef          	jal	80003298 <iupdate>

  return tot;
    800038b2:	0009851b          	sext.w	a0,s3
    800038b6:	69a6                	ld	s3,72(sp)
}
    800038b8:	70a6                	ld	ra,104(sp)
    800038ba:	7406                	ld	s0,96(sp)
    800038bc:	6946                	ld	s2,80(sp)
    800038be:	6a06                	ld	s4,64(sp)
    800038c0:	7ae2                	ld	s5,56(sp)
    800038c2:	7b42                	ld	s6,48(sp)
    800038c4:	7ba2                	ld	s7,40(sp)
    800038c6:	6165                	addi	sp,sp,112
    800038c8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800038ca:	89da                	mv	s3,s6
    800038cc:	b7c5                	j	800038ac <writei+0xd4>
    800038ce:	64e6                	ld	s1,88(sp)
    800038d0:	7c02                	ld	s8,32(sp)
    800038d2:	6ce2                	ld	s9,24(sp)
    800038d4:	6d42                	ld	s10,16(sp)
    800038d6:	6da2                	ld	s11,8(sp)
    800038d8:	bfd1                	j	800038ac <writei+0xd4>
    return -1;
    800038da:	557d                	li	a0,-1
}
    800038dc:	8082                	ret
    return -1;
    800038de:	557d                	li	a0,-1
    800038e0:	bfe1                	j	800038b8 <writei+0xe0>
    return -1;
    800038e2:	557d                	li	a0,-1
    800038e4:	bfd1                	j	800038b8 <writei+0xe0>

00000000800038e6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800038e6:	1141                	addi	sp,sp,-16
    800038e8:	e406                	sd	ra,8(sp)
    800038ea:	e022                	sd	s0,0(sp)
    800038ec:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800038ee:	4639                	li	a2,14
    800038f0:	c7efd0ef          	jal	80000d6e <strncmp>
}
    800038f4:	60a2                	ld	ra,8(sp)
    800038f6:	6402                	ld	s0,0(sp)
    800038f8:	0141                	addi	sp,sp,16
    800038fa:	8082                	ret

00000000800038fc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800038fc:	7139                	addi	sp,sp,-64
    800038fe:	fc06                	sd	ra,56(sp)
    80003900:	f822                	sd	s0,48(sp)
    80003902:	f426                	sd	s1,40(sp)
    80003904:	f04a                	sd	s2,32(sp)
    80003906:	ec4e                	sd	s3,24(sp)
    80003908:	e852                	sd	s4,16(sp)
    8000390a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000390c:	04451703          	lh	a4,68(a0)
    80003910:	4785                	li	a5,1
    80003912:	00f71a63          	bne	a4,a5,80003926 <dirlookup+0x2a>
    80003916:	892a                	mv	s2,a0
    80003918:	89ae                	mv	s3,a1
    8000391a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000391c:	457c                	lw	a5,76(a0)
    8000391e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003920:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003922:	e39d                	bnez	a5,80003948 <dirlookup+0x4c>
    80003924:	a095                	j	80003988 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003926:	00004517          	auipc	a0,0x4
    8000392a:	b9a50513          	addi	a0,a0,-1126 # 800074c0 <etext+0x4c0>
    8000392e:	eb3fc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80003932:	00004517          	auipc	a0,0x4
    80003936:	ba650513          	addi	a0,a0,-1114 # 800074d8 <etext+0x4d8>
    8000393a:	ea7fc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000393e:	24c1                	addiw	s1,s1,16
    80003940:	04c92783          	lw	a5,76(s2)
    80003944:	04f4f163          	bgeu	s1,a5,80003986 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003948:	4741                	li	a4,16
    8000394a:	86a6                	mv	a3,s1
    8000394c:	fc040613          	addi	a2,s0,-64
    80003950:	4581                	li	a1,0
    80003952:	854a                	mv	a0,s2
    80003954:	d89ff0ef          	jal	800036dc <readi>
    80003958:	47c1                	li	a5,16
    8000395a:	fcf51ce3          	bne	a0,a5,80003932 <dirlookup+0x36>
    if(de.inum == 0)
    8000395e:	fc045783          	lhu	a5,-64(s0)
    80003962:	dff1                	beqz	a5,8000393e <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003964:	fc240593          	addi	a1,s0,-62
    80003968:	854e                	mv	a0,s3
    8000396a:	f7dff0ef          	jal	800038e6 <namecmp>
    8000396e:	f961                	bnez	a0,8000393e <dirlookup+0x42>
      if(poff)
    80003970:	000a0463          	beqz	s4,80003978 <dirlookup+0x7c>
        *poff = off;
    80003974:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003978:	fc045583          	lhu	a1,-64(s0)
    8000397c:	00092503          	lw	a0,0(s2)
    80003980:	f58ff0ef          	jal	800030d8 <iget>
    80003984:	a011                	j	80003988 <dirlookup+0x8c>
  return 0;
    80003986:	4501                	li	a0,0
}
    80003988:	70e2                	ld	ra,56(sp)
    8000398a:	7442                	ld	s0,48(sp)
    8000398c:	74a2                	ld	s1,40(sp)
    8000398e:	7902                	ld	s2,32(sp)
    80003990:	69e2                	ld	s3,24(sp)
    80003992:	6a42                	ld	s4,16(sp)
    80003994:	6121                	addi	sp,sp,64
    80003996:	8082                	ret

0000000080003998 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003998:	711d                	addi	sp,sp,-96
    8000399a:	ec86                	sd	ra,88(sp)
    8000399c:	e8a2                	sd	s0,80(sp)
    8000399e:	e4a6                	sd	s1,72(sp)
    800039a0:	e0ca                	sd	s2,64(sp)
    800039a2:	fc4e                	sd	s3,56(sp)
    800039a4:	f852                	sd	s4,48(sp)
    800039a6:	f456                	sd	s5,40(sp)
    800039a8:	f05a                	sd	s6,32(sp)
    800039aa:	ec5e                	sd	s7,24(sp)
    800039ac:	e862                	sd	s8,16(sp)
    800039ae:	e466                	sd	s9,8(sp)
    800039b0:	1080                	addi	s0,sp,96
    800039b2:	84aa                	mv	s1,a0
    800039b4:	8b2e                	mv	s6,a1
    800039b6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800039b8:	00054703          	lbu	a4,0(a0)
    800039bc:	02f00793          	li	a5,47
    800039c0:	00f70e63          	beq	a4,a5,800039dc <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800039c4:	f0bfd0ef          	jal	800018ce <myproc>
    800039c8:	15053503          	ld	a0,336(a0)
    800039cc:	94bff0ef          	jal	80003316 <idup>
    800039d0:	8a2a                	mv	s4,a0
  while(*path == '/')
    800039d2:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800039d6:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800039d8:	4b85                	li	s7,1
    800039da:	a871                	j	80003a76 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    800039dc:	4585                	li	a1,1
    800039de:	4505                	li	a0,1
    800039e0:	ef8ff0ef          	jal	800030d8 <iget>
    800039e4:	8a2a                	mv	s4,a0
    800039e6:	b7f5                	j	800039d2 <namex+0x3a>
      iunlockput(ip);
    800039e8:	8552                	mv	a0,s4
    800039ea:	b6dff0ef          	jal	80003556 <iunlockput>
      return 0;
    800039ee:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800039f0:	8552                	mv	a0,s4
    800039f2:	60e6                	ld	ra,88(sp)
    800039f4:	6446                	ld	s0,80(sp)
    800039f6:	64a6                	ld	s1,72(sp)
    800039f8:	6906                	ld	s2,64(sp)
    800039fa:	79e2                	ld	s3,56(sp)
    800039fc:	7a42                	ld	s4,48(sp)
    800039fe:	7aa2                	ld	s5,40(sp)
    80003a00:	7b02                	ld	s6,32(sp)
    80003a02:	6be2                	ld	s7,24(sp)
    80003a04:	6c42                	ld	s8,16(sp)
    80003a06:	6ca2                	ld	s9,8(sp)
    80003a08:	6125                	addi	sp,sp,96
    80003a0a:	8082                	ret
      iunlock(ip);
    80003a0c:	8552                	mv	a0,s4
    80003a0e:	9edff0ef          	jal	800033fa <iunlock>
      return ip;
    80003a12:	bff9                	j	800039f0 <namex+0x58>
      iunlockput(ip);
    80003a14:	8552                	mv	a0,s4
    80003a16:	b41ff0ef          	jal	80003556 <iunlockput>
      return 0;
    80003a1a:	8a4e                	mv	s4,s3
    80003a1c:	bfd1                	j	800039f0 <namex+0x58>
  len = path - s;
    80003a1e:	40998633          	sub	a2,s3,s1
    80003a22:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003a26:	099c5063          	bge	s8,s9,80003aa6 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80003a2a:	4639                	li	a2,14
    80003a2c:	85a6                	mv	a1,s1
    80003a2e:	8556                	mv	a0,s5
    80003a30:	acefd0ef          	jal	80000cfe <memmove>
    80003a34:	84ce                	mv	s1,s3
  while(*path == '/')
    80003a36:	0004c783          	lbu	a5,0(s1)
    80003a3a:	01279763          	bne	a5,s2,80003a48 <namex+0xb0>
    path++;
    80003a3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003a40:	0004c783          	lbu	a5,0(s1)
    80003a44:	ff278de3          	beq	a5,s2,80003a3e <namex+0xa6>
    ilock(ip);
    80003a48:	8552                	mv	a0,s4
    80003a4a:	903ff0ef          	jal	8000334c <ilock>
    if(ip->type != T_DIR){
    80003a4e:	044a1783          	lh	a5,68(s4)
    80003a52:	f9779be3          	bne	a5,s7,800039e8 <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003a56:	000b0563          	beqz	s6,80003a60 <namex+0xc8>
    80003a5a:	0004c783          	lbu	a5,0(s1)
    80003a5e:	d7dd                	beqz	a5,80003a0c <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003a60:	4601                	li	a2,0
    80003a62:	85d6                	mv	a1,s5
    80003a64:	8552                	mv	a0,s4
    80003a66:	e97ff0ef          	jal	800038fc <dirlookup>
    80003a6a:	89aa                	mv	s3,a0
    80003a6c:	d545                	beqz	a0,80003a14 <namex+0x7c>
    iunlockput(ip);
    80003a6e:	8552                	mv	a0,s4
    80003a70:	ae7ff0ef          	jal	80003556 <iunlockput>
    ip = next;
    80003a74:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003a76:	0004c783          	lbu	a5,0(s1)
    80003a7a:	01279763          	bne	a5,s2,80003a88 <namex+0xf0>
    path++;
    80003a7e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003a80:	0004c783          	lbu	a5,0(s1)
    80003a84:	ff278de3          	beq	a5,s2,80003a7e <namex+0xe6>
  if(*path == 0)
    80003a88:	cb8d                	beqz	a5,80003aba <namex+0x122>
  while(*path != '/' && *path != 0)
    80003a8a:	0004c783          	lbu	a5,0(s1)
    80003a8e:	89a6                	mv	s3,s1
  len = path - s;
    80003a90:	4c81                	li	s9,0
    80003a92:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003a94:	01278963          	beq	a5,s2,80003aa6 <namex+0x10e>
    80003a98:	d3d9                	beqz	a5,80003a1e <namex+0x86>
    path++;
    80003a9a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003a9c:	0009c783          	lbu	a5,0(s3)
    80003aa0:	ff279ce3          	bne	a5,s2,80003a98 <namex+0x100>
    80003aa4:	bfad                	j	80003a1e <namex+0x86>
    memmove(name, s, len);
    80003aa6:	2601                	sext.w	a2,a2
    80003aa8:	85a6                	mv	a1,s1
    80003aaa:	8556                	mv	a0,s5
    80003aac:	a52fd0ef          	jal	80000cfe <memmove>
    name[len] = 0;
    80003ab0:	9cd6                	add	s9,s9,s5
    80003ab2:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003ab6:	84ce                	mv	s1,s3
    80003ab8:	bfbd                	j	80003a36 <namex+0x9e>
  if(nameiparent){
    80003aba:	f20b0be3          	beqz	s6,800039f0 <namex+0x58>
    iput(ip);
    80003abe:	8552                	mv	a0,s4
    80003ac0:	a0fff0ef          	jal	800034ce <iput>
    return 0;
    80003ac4:	4a01                	li	s4,0
    80003ac6:	b72d                	j	800039f0 <namex+0x58>

0000000080003ac8 <dirlink>:
{
    80003ac8:	7139                	addi	sp,sp,-64
    80003aca:	fc06                	sd	ra,56(sp)
    80003acc:	f822                	sd	s0,48(sp)
    80003ace:	f04a                	sd	s2,32(sp)
    80003ad0:	ec4e                	sd	s3,24(sp)
    80003ad2:	e852                	sd	s4,16(sp)
    80003ad4:	0080                	addi	s0,sp,64
    80003ad6:	892a                	mv	s2,a0
    80003ad8:	8a2e                	mv	s4,a1
    80003ada:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003adc:	4601                	li	a2,0
    80003ade:	e1fff0ef          	jal	800038fc <dirlookup>
    80003ae2:	e535                	bnez	a0,80003b4e <dirlink+0x86>
    80003ae4:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ae6:	04c92483          	lw	s1,76(s2)
    80003aea:	c48d                	beqz	s1,80003b14 <dirlink+0x4c>
    80003aec:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003aee:	4741                	li	a4,16
    80003af0:	86a6                	mv	a3,s1
    80003af2:	fc040613          	addi	a2,s0,-64
    80003af6:	4581                	li	a1,0
    80003af8:	854a                	mv	a0,s2
    80003afa:	be3ff0ef          	jal	800036dc <readi>
    80003afe:	47c1                	li	a5,16
    80003b00:	04f51b63          	bne	a0,a5,80003b56 <dirlink+0x8e>
    if(de.inum == 0)
    80003b04:	fc045783          	lhu	a5,-64(s0)
    80003b08:	c791                	beqz	a5,80003b14 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b0a:	24c1                	addiw	s1,s1,16
    80003b0c:	04c92783          	lw	a5,76(s2)
    80003b10:	fcf4efe3          	bltu	s1,a5,80003aee <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003b14:	4639                	li	a2,14
    80003b16:	85d2                	mv	a1,s4
    80003b18:	fc240513          	addi	a0,s0,-62
    80003b1c:	a88fd0ef          	jal	80000da4 <strncpy>
  de.inum = inum;
    80003b20:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b24:	4741                	li	a4,16
    80003b26:	86a6                	mv	a3,s1
    80003b28:	fc040613          	addi	a2,s0,-64
    80003b2c:	4581                	li	a1,0
    80003b2e:	854a                	mv	a0,s2
    80003b30:	ca9ff0ef          	jal	800037d8 <writei>
    80003b34:	1541                	addi	a0,a0,-16
    80003b36:	00a03533          	snez	a0,a0
    80003b3a:	40a00533          	neg	a0,a0
    80003b3e:	74a2                	ld	s1,40(sp)
}
    80003b40:	70e2                	ld	ra,56(sp)
    80003b42:	7442                	ld	s0,48(sp)
    80003b44:	7902                	ld	s2,32(sp)
    80003b46:	69e2                	ld	s3,24(sp)
    80003b48:	6a42                	ld	s4,16(sp)
    80003b4a:	6121                	addi	sp,sp,64
    80003b4c:	8082                	ret
    iput(ip);
    80003b4e:	981ff0ef          	jal	800034ce <iput>
    return -1;
    80003b52:	557d                	li	a0,-1
    80003b54:	b7f5                	j	80003b40 <dirlink+0x78>
      panic("dirlink read");
    80003b56:	00004517          	auipc	a0,0x4
    80003b5a:	99250513          	addi	a0,a0,-1646 # 800074e8 <etext+0x4e8>
    80003b5e:	c83fc0ef          	jal	800007e0 <panic>

0000000080003b62 <namei>:

struct inode*
namei(char *path)
{
    80003b62:	1101                	addi	sp,sp,-32
    80003b64:	ec06                	sd	ra,24(sp)
    80003b66:	e822                	sd	s0,16(sp)
    80003b68:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003b6a:	fe040613          	addi	a2,s0,-32
    80003b6e:	4581                	li	a1,0
    80003b70:	e29ff0ef          	jal	80003998 <namex>
}
    80003b74:	60e2                	ld	ra,24(sp)
    80003b76:	6442                	ld	s0,16(sp)
    80003b78:	6105                	addi	sp,sp,32
    80003b7a:	8082                	ret

0000000080003b7c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003b7c:	1141                	addi	sp,sp,-16
    80003b7e:	e406                	sd	ra,8(sp)
    80003b80:	e022                	sd	s0,0(sp)
    80003b82:	0800                	addi	s0,sp,16
    80003b84:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003b86:	4585                	li	a1,1
    80003b88:	e11ff0ef          	jal	80003998 <namex>
}
    80003b8c:	60a2                	ld	ra,8(sp)
    80003b8e:	6402                	ld	s0,0(sp)
    80003b90:	0141                	addi	sp,sp,16
    80003b92:	8082                	ret

0000000080003b94 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003b94:	1101                	addi	sp,sp,-32
    80003b96:	ec06                	sd	ra,24(sp)
    80003b98:	e822                	sd	s0,16(sp)
    80003b9a:	e426                	sd	s1,8(sp)
    80003b9c:	e04a                	sd	s2,0(sp)
    80003b9e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ba0:	0001f917          	auipc	s2,0x1f
    80003ba4:	9a890913          	addi	s2,s2,-1624 # 80022548 <log>
    80003ba8:	01892583          	lw	a1,24(s2)
    80003bac:	02492503          	lw	a0,36(s2)
    80003bb0:	8d0ff0ef          	jal	80002c80 <bread>
    80003bb4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003bb6:	02892603          	lw	a2,40(s2)
    80003bba:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003bbc:	00c05f63          	blez	a2,80003bda <write_head+0x46>
    80003bc0:	0001f717          	auipc	a4,0x1f
    80003bc4:	9b470713          	addi	a4,a4,-1612 # 80022574 <log+0x2c>
    80003bc8:	87aa                	mv	a5,a0
    80003bca:	060a                	slli	a2,a2,0x2
    80003bcc:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003bce:	4314                	lw	a3,0(a4)
    80003bd0:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003bd2:	0711                	addi	a4,a4,4
    80003bd4:	0791                	addi	a5,a5,4
    80003bd6:	fec79ce3          	bne	a5,a2,80003bce <write_head+0x3a>
  }
  bwrite(buf);
    80003bda:	8526                	mv	a0,s1
    80003bdc:	97aff0ef          	jal	80002d56 <bwrite>
  brelse(buf);
    80003be0:	8526                	mv	a0,s1
    80003be2:	9a6ff0ef          	jal	80002d88 <brelse>
}
    80003be6:	60e2                	ld	ra,24(sp)
    80003be8:	6442                	ld	s0,16(sp)
    80003bea:	64a2                	ld	s1,8(sp)
    80003bec:	6902                	ld	s2,0(sp)
    80003bee:	6105                	addi	sp,sp,32
    80003bf0:	8082                	ret

0000000080003bf2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003bf2:	0001f797          	auipc	a5,0x1f
    80003bf6:	97e7a783          	lw	a5,-1666(a5) # 80022570 <log+0x28>
    80003bfa:	0af05e63          	blez	a5,80003cb6 <install_trans+0xc4>
{
    80003bfe:	715d                	addi	sp,sp,-80
    80003c00:	e486                	sd	ra,72(sp)
    80003c02:	e0a2                	sd	s0,64(sp)
    80003c04:	fc26                	sd	s1,56(sp)
    80003c06:	f84a                	sd	s2,48(sp)
    80003c08:	f44e                	sd	s3,40(sp)
    80003c0a:	f052                	sd	s4,32(sp)
    80003c0c:	ec56                	sd	s5,24(sp)
    80003c0e:	e85a                	sd	s6,16(sp)
    80003c10:	e45e                	sd	s7,8(sp)
    80003c12:	0880                	addi	s0,sp,80
    80003c14:	8b2a                	mv	s6,a0
    80003c16:	0001fa97          	auipc	s5,0x1f
    80003c1a:	95ea8a93          	addi	s5,s5,-1698 # 80022574 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c1e:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003c20:	00004b97          	auipc	s7,0x4
    80003c24:	8d8b8b93          	addi	s7,s7,-1832 # 800074f8 <etext+0x4f8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003c28:	0001fa17          	auipc	s4,0x1f
    80003c2c:	920a0a13          	addi	s4,s4,-1760 # 80022548 <log>
    80003c30:	a025                	j	80003c58 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003c32:	000aa603          	lw	a2,0(s5)
    80003c36:	85ce                	mv	a1,s3
    80003c38:	855e                	mv	a0,s7
    80003c3a:	8c1fc0ef          	jal	800004fa <printf>
    80003c3e:	a839                	j	80003c5c <install_trans+0x6a>
    brelse(lbuf);
    80003c40:	854a                	mv	a0,s2
    80003c42:	946ff0ef          	jal	80002d88 <brelse>
    brelse(dbuf);
    80003c46:	8526                	mv	a0,s1
    80003c48:	940ff0ef          	jal	80002d88 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003c4c:	2985                	addiw	s3,s3,1
    80003c4e:	0a91                	addi	s5,s5,4
    80003c50:	028a2783          	lw	a5,40(s4)
    80003c54:	04f9d663          	bge	s3,a5,80003ca0 <install_trans+0xae>
    if(recovering) {
    80003c58:	fc0b1de3          	bnez	s6,80003c32 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003c5c:	018a2583          	lw	a1,24(s4)
    80003c60:	013585bb          	addw	a1,a1,s3
    80003c64:	2585                	addiw	a1,a1,1
    80003c66:	024a2503          	lw	a0,36(s4)
    80003c6a:	816ff0ef          	jal	80002c80 <bread>
    80003c6e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003c70:	000aa583          	lw	a1,0(s5)
    80003c74:	024a2503          	lw	a0,36(s4)
    80003c78:	808ff0ef          	jal	80002c80 <bread>
    80003c7c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003c7e:	40000613          	li	a2,1024
    80003c82:	05890593          	addi	a1,s2,88
    80003c86:	05850513          	addi	a0,a0,88
    80003c8a:	874fd0ef          	jal	80000cfe <memmove>
    bwrite(dbuf);  // write dst to disk
    80003c8e:	8526                	mv	a0,s1
    80003c90:	8c6ff0ef          	jal	80002d56 <bwrite>
    if(recovering == 0)
    80003c94:	fa0b16e3          	bnez	s6,80003c40 <install_trans+0x4e>
      bunpin(dbuf);
    80003c98:	8526                	mv	a0,s1
    80003c9a:	9aaff0ef          	jal	80002e44 <bunpin>
    80003c9e:	b74d                	j	80003c40 <install_trans+0x4e>
}
    80003ca0:	60a6                	ld	ra,72(sp)
    80003ca2:	6406                	ld	s0,64(sp)
    80003ca4:	74e2                	ld	s1,56(sp)
    80003ca6:	7942                	ld	s2,48(sp)
    80003ca8:	79a2                	ld	s3,40(sp)
    80003caa:	7a02                	ld	s4,32(sp)
    80003cac:	6ae2                	ld	s5,24(sp)
    80003cae:	6b42                	ld	s6,16(sp)
    80003cb0:	6ba2                	ld	s7,8(sp)
    80003cb2:	6161                	addi	sp,sp,80
    80003cb4:	8082                	ret
    80003cb6:	8082                	ret

0000000080003cb8 <initlog>:
{
    80003cb8:	7179                	addi	sp,sp,-48
    80003cba:	f406                	sd	ra,40(sp)
    80003cbc:	f022                	sd	s0,32(sp)
    80003cbe:	ec26                	sd	s1,24(sp)
    80003cc0:	e84a                	sd	s2,16(sp)
    80003cc2:	e44e                	sd	s3,8(sp)
    80003cc4:	1800                	addi	s0,sp,48
    80003cc6:	892a                	mv	s2,a0
    80003cc8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003cca:	0001f497          	auipc	s1,0x1f
    80003cce:	87e48493          	addi	s1,s1,-1922 # 80022548 <log>
    80003cd2:	00004597          	auipc	a1,0x4
    80003cd6:	84658593          	addi	a1,a1,-1978 # 80007518 <etext+0x518>
    80003cda:	8526                	mv	a0,s1
    80003cdc:	e73fc0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    80003ce0:	0149a583          	lw	a1,20(s3)
    80003ce4:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003ce6:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003cea:	854a                	mv	a0,s2
    80003cec:	f95fe0ef          	jal	80002c80 <bread>
  log.lh.n = lh->n;
    80003cf0:	4d30                	lw	a2,88(a0)
    80003cf2:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003cf4:	00c05f63          	blez	a2,80003d12 <initlog+0x5a>
    80003cf8:	87aa                	mv	a5,a0
    80003cfa:	0001f717          	auipc	a4,0x1f
    80003cfe:	87a70713          	addi	a4,a4,-1926 # 80022574 <log+0x2c>
    80003d02:	060a                	slli	a2,a2,0x2
    80003d04:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003d06:	4ff4                	lw	a3,92(a5)
    80003d08:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003d0a:	0791                	addi	a5,a5,4
    80003d0c:	0711                	addi	a4,a4,4
    80003d0e:	fec79ce3          	bne	a5,a2,80003d06 <initlog+0x4e>
  brelse(buf);
    80003d12:	876ff0ef          	jal	80002d88 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003d16:	4505                	li	a0,1
    80003d18:	edbff0ef          	jal	80003bf2 <install_trans>
  log.lh.n = 0;
    80003d1c:	0001f797          	auipc	a5,0x1f
    80003d20:	8407aa23          	sw	zero,-1964(a5) # 80022570 <log+0x28>
  write_head(); // clear the log
    80003d24:	e71ff0ef          	jal	80003b94 <write_head>
}
    80003d28:	70a2                	ld	ra,40(sp)
    80003d2a:	7402                	ld	s0,32(sp)
    80003d2c:	64e2                	ld	s1,24(sp)
    80003d2e:	6942                	ld	s2,16(sp)
    80003d30:	69a2                	ld	s3,8(sp)
    80003d32:	6145                	addi	sp,sp,48
    80003d34:	8082                	ret

0000000080003d36 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003d36:	1101                	addi	sp,sp,-32
    80003d38:	ec06                	sd	ra,24(sp)
    80003d3a:	e822                	sd	s0,16(sp)
    80003d3c:	e426                	sd	s1,8(sp)
    80003d3e:	e04a                	sd	s2,0(sp)
    80003d40:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003d42:	0001f517          	auipc	a0,0x1f
    80003d46:	80650513          	addi	a0,a0,-2042 # 80022548 <log>
    80003d4a:	e85fc0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    80003d4e:	0001e497          	auipc	s1,0x1e
    80003d52:	7fa48493          	addi	s1,s1,2042 # 80022548 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003d56:	4979                	li	s2,30
    80003d58:	a029                	j	80003d62 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003d5a:	85a6                	mv	a1,s1
    80003d5c:	8526                	mv	a0,s1
    80003d5e:	9dcfe0ef          	jal	80001f3a <sleep>
    if(log.committing){
    80003d62:	509c                	lw	a5,32(s1)
    80003d64:	fbfd                	bnez	a5,80003d5a <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003d66:	4cd8                	lw	a4,28(s1)
    80003d68:	2705                	addiw	a4,a4,1
    80003d6a:	0027179b          	slliw	a5,a4,0x2
    80003d6e:	9fb9                	addw	a5,a5,a4
    80003d70:	0017979b          	slliw	a5,a5,0x1
    80003d74:	5494                	lw	a3,40(s1)
    80003d76:	9fb5                	addw	a5,a5,a3
    80003d78:	00f95763          	bge	s2,a5,80003d86 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003d7c:	85a6                	mv	a1,s1
    80003d7e:	8526                	mv	a0,s1
    80003d80:	9bafe0ef          	jal	80001f3a <sleep>
    80003d84:	bff9                	j	80003d62 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003d86:	0001e517          	auipc	a0,0x1e
    80003d8a:	7c250513          	addi	a0,a0,1986 # 80022548 <log>
    80003d8e:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003d90:	ed7fc0ef          	jal	80000c66 <release>
      break;
    }
  }
}
    80003d94:	60e2                	ld	ra,24(sp)
    80003d96:	6442                	ld	s0,16(sp)
    80003d98:	64a2                	ld	s1,8(sp)
    80003d9a:	6902                	ld	s2,0(sp)
    80003d9c:	6105                	addi	sp,sp,32
    80003d9e:	8082                	ret

0000000080003da0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003da0:	7139                	addi	sp,sp,-64
    80003da2:	fc06                	sd	ra,56(sp)
    80003da4:	f822                	sd	s0,48(sp)
    80003da6:	f426                	sd	s1,40(sp)
    80003da8:	f04a                	sd	s2,32(sp)
    80003daa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003dac:	0001e497          	auipc	s1,0x1e
    80003db0:	79c48493          	addi	s1,s1,1948 # 80022548 <log>
    80003db4:	8526                	mv	a0,s1
    80003db6:	e19fc0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    80003dba:	4cdc                	lw	a5,28(s1)
    80003dbc:	37fd                	addiw	a5,a5,-1
    80003dbe:	0007891b          	sext.w	s2,a5
    80003dc2:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003dc4:	509c                	lw	a5,32(s1)
    80003dc6:	ef9d                	bnez	a5,80003e04 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80003dc8:	04091763          	bnez	s2,80003e16 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003dcc:	0001e497          	auipc	s1,0x1e
    80003dd0:	77c48493          	addi	s1,s1,1916 # 80022548 <log>
    80003dd4:	4785                	li	a5,1
    80003dd6:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003dd8:	8526                	mv	a0,s1
    80003dda:	e8dfc0ef          	jal	80000c66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003dde:	549c                	lw	a5,40(s1)
    80003de0:	04f04b63          	bgtz	a5,80003e36 <end_op+0x96>
    acquire(&log.lock);
    80003de4:	0001e497          	auipc	s1,0x1e
    80003de8:	76448493          	addi	s1,s1,1892 # 80022548 <log>
    80003dec:	8526                	mv	a0,s1
    80003dee:	de1fc0ef          	jal	80000bce <acquire>
    log.committing = 0;
    80003df2:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003df6:	8526                	mv	a0,s1
    80003df8:	98efe0ef          	jal	80001f86 <wakeup>
    release(&log.lock);
    80003dfc:	8526                	mv	a0,s1
    80003dfe:	e69fc0ef          	jal	80000c66 <release>
}
    80003e02:	a025                	j	80003e2a <end_op+0x8a>
    80003e04:	ec4e                	sd	s3,24(sp)
    80003e06:	e852                	sd	s4,16(sp)
    80003e08:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80003e0a:	00003517          	auipc	a0,0x3
    80003e0e:	71650513          	addi	a0,a0,1814 # 80007520 <etext+0x520>
    80003e12:	9cffc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80003e16:	0001e497          	auipc	s1,0x1e
    80003e1a:	73248493          	addi	s1,s1,1842 # 80022548 <log>
    80003e1e:	8526                	mv	a0,s1
    80003e20:	966fe0ef          	jal	80001f86 <wakeup>
  release(&log.lock);
    80003e24:	8526                	mv	a0,s1
    80003e26:	e41fc0ef          	jal	80000c66 <release>
}
    80003e2a:	70e2                	ld	ra,56(sp)
    80003e2c:	7442                	ld	s0,48(sp)
    80003e2e:	74a2                	ld	s1,40(sp)
    80003e30:	7902                	ld	s2,32(sp)
    80003e32:	6121                	addi	sp,sp,64
    80003e34:	8082                	ret
    80003e36:	ec4e                	sd	s3,24(sp)
    80003e38:	e852                	sd	s4,16(sp)
    80003e3a:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e3c:	0001ea97          	auipc	s5,0x1e
    80003e40:	738a8a93          	addi	s5,s5,1848 # 80022574 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003e44:	0001ea17          	auipc	s4,0x1e
    80003e48:	704a0a13          	addi	s4,s4,1796 # 80022548 <log>
    80003e4c:	018a2583          	lw	a1,24(s4)
    80003e50:	012585bb          	addw	a1,a1,s2
    80003e54:	2585                	addiw	a1,a1,1
    80003e56:	024a2503          	lw	a0,36(s4)
    80003e5a:	e27fe0ef          	jal	80002c80 <bread>
    80003e5e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003e60:	000aa583          	lw	a1,0(s5)
    80003e64:	024a2503          	lw	a0,36(s4)
    80003e68:	e19fe0ef          	jal	80002c80 <bread>
    80003e6c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003e6e:	40000613          	li	a2,1024
    80003e72:	05850593          	addi	a1,a0,88
    80003e76:	05848513          	addi	a0,s1,88
    80003e7a:	e85fc0ef          	jal	80000cfe <memmove>
    bwrite(to);  // write the log
    80003e7e:	8526                	mv	a0,s1
    80003e80:	ed7fe0ef          	jal	80002d56 <bwrite>
    brelse(from);
    80003e84:	854e                	mv	a0,s3
    80003e86:	f03fe0ef          	jal	80002d88 <brelse>
    brelse(to);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	efdfe0ef          	jal	80002d88 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e90:	2905                	addiw	s2,s2,1
    80003e92:	0a91                	addi	s5,s5,4
    80003e94:	028a2783          	lw	a5,40(s4)
    80003e98:	faf94ae3          	blt	s2,a5,80003e4c <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003e9c:	cf9ff0ef          	jal	80003b94 <write_head>
    install_trans(0); // Now install writes to home locations
    80003ea0:	4501                	li	a0,0
    80003ea2:	d51ff0ef          	jal	80003bf2 <install_trans>
    log.lh.n = 0;
    80003ea6:	0001e797          	auipc	a5,0x1e
    80003eaa:	6c07a523          	sw	zero,1738(a5) # 80022570 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003eae:	ce7ff0ef          	jal	80003b94 <write_head>
    80003eb2:	69e2                	ld	s3,24(sp)
    80003eb4:	6a42                	ld	s4,16(sp)
    80003eb6:	6aa2                	ld	s5,8(sp)
    80003eb8:	b735                	j	80003de4 <end_op+0x44>

0000000080003eba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003eba:	1101                	addi	sp,sp,-32
    80003ebc:	ec06                	sd	ra,24(sp)
    80003ebe:	e822                	sd	s0,16(sp)
    80003ec0:	e426                	sd	s1,8(sp)
    80003ec2:	e04a                	sd	s2,0(sp)
    80003ec4:	1000                	addi	s0,sp,32
    80003ec6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003ec8:	0001e917          	auipc	s2,0x1e
    80003ecc:	68090913          	addi	s2,s2,1664 # 80022548 <log>
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	cfdfc0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003ed6:	02892603          	lw	a2,40(s2)
    80003eda:	47f5                	li	a5,29
    80003edc:	04c7cc63          	blt	a5,a2,80003f34 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003ee0:	0001e797          	auipc	a5,0x1e
    80003ee4:	6847a783          	lw	a5,1668(a5) # 80022564 <log+0x1c>
    80003ee8:	04f05c63          	blez	a5,80003f40 <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003eec:	4781                	li	a5,0
    80003eee:	04c05f63          	blez	a2,80003f4c <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003ef2:	44cc                	lw	a1,12(s1)
    80003ef4:	0001e717          	auipc	a4,0x1e
    80003ef8:	68070713          	addi	a4,a4,1664 # 80022574 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003efc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003efe:	4314                	lw	a3,0(a4)
    80003f00:	04b68663          	beq	a3,a1,80003f4c <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003f04:	2785                	addiw	a5,a5,1
    80003f06:	0711                	addi	a4,a4,4
    80003f08:	fef61be3          	bne	a2,a5,80003efe <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003f0c:	0621                	addi	a2,a2,8
    80003f0e:	060a                	slli	a2,a2,0x2
    80003f10:	0001e797          	auipc	a5,0x1e
    80003f14:	63878793          	addi	a5,a5,1592 # 80022548 <log>
    80003f18:	97b2                	add	a5,a5,a2
    80003f1a:	44d8                	lw	a4,12(s1)
    80003f1c:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003f1e:	8526                	mv	a0,s1
    80003f20:	ef1fe0ef          	jal	80002e10 <bpin>
    log.lh.n++;
    80003f24:	0001e717          	auipc	a4,0x1e
    80003f28:	62470713          	addi	a4,a4,1572 # 80022548 <log>
    80003f2c:	571c                	lw	a5,40(a4)
    80003f2e:	2785                	addiw	a5,a5,1
    80003f30:	d71c                	sw	a5,40(a4)
    80003f32:	a80d                	j	80003f64 <log_write+0xaa>
    panic("too big a transaction");
    80003f34:	00003517          	auipc	a0,0x3
    80003f38:	5fc50513          	addi	a0,a0,1532 # 80007530 <etext+0x530>
    80003f3c:	8a5fc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    80003f40:	00003517          	auipc	a0,0x3
    80003f44:	60850513          	addi	a0,a0,1544 # 80007548 <etext+0x548>
    80003f48:	899fc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    80003f4c:	00878693          	addi	a3,a5,8
    80003f50:	068a                	slli	a3,a3,0x2
    80003f52:	0001e717          	auipc	a4,0x1e
    80003f56:	5f670713          	addi	a4,a4,1526 # 80022548 <log>
    80003f5a:	9736                	add	a4,a4,a3
    80003f5c:	44d4                	lw	a3,12(s1)
    80003f5e:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003f60:	faf60fe3          	beq	a2,a5,80003f1e <log_write+0x64>
  }
  release(&log.lock);
    80003f64:	0001e517          	auipc	a0,0x1e
    80003f68:	5e450513          	addi	a0,a0,1508 # 80022548 <log>
    80003f6c:	cfbfc0ef          	jal	80000c66 <release>
}
    80003f70:	60e2                	ld	ra,24(sp)
    80003f72:	6442                	ld	s0,16(sp)
    80003f74:	64a2                	ld	s1,8(sp)
    80003f76:	6902                	ld	s2,0(sp)
    80003f78:	6105                	addi	sp,sp,32
    80003f7a:	8082                	ret

0000000080003f7c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003f7c:	1101                	addi	sp,sp,-32
    80003f7e:	ec06                	sd	ra,24(sp)
    80003f80:	e822                	sd	s0,16(sp)
    80003f82:	e426                	sd	s1,8(sp)
    80003f84:	e04a                	sd	s2,0(sp)
    80003f86:	1000                	addi	s0,sp,32
    80003f88:	84aa                	mv	s1,a0
    80003f8a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003f8c:	00003597          	auipc	a1,0x3
    80003f90:	5dc58593          	addi	a1,a1,1500 # 80007568 <etext+0x568>
    80003f94:	0521                	addi	a0,a0,8
    80003f96:	bb9fc0ef          	jal	80000b4e <initlock>
  lk->name = name;
    80003f9a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003f9e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003fa2:	0204a423          	sw	zero,40(s1)
}
    80003fa6:	60e2                	ld	ra,24(sp)
    80003fa8:	6442                	ld	s0,16(sp)
    80003faa:	64a2                	ld	s1,8(sp)
    80003fac:	6902                	ld	s2,0(sp)
    80003fae:	6105                	addi	sp,sp,32
    80003fb0:	8082                	ret

0000000080003fb2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003fb2:	1101                	addi	sp,sp,-32
    80003fb4:	ec06                	sd	ra,24(sp)
    80003fb6:	e822                	sd	s0,16(sp)
    80003fb8:	e426                	sd	s1,8(sp)
    80003fba:	e04a                	sd	s2,0(sp)
    80003fbc:	1000                	addi	s0,sp,32
    80003fbe:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003fc0:	00850913          	addi	s2,a0,8
    80003fc4:	854a                	mv	a0,s2
    80003fc6:	c09fc0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    80003fca:	409c                	lw	a5,0(s1)
    80003fcc:	c799                	beqz	a5,80003fda <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003fce:	85ca                	mv	a1,s2
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	f69fd0ef          	jal	80001f3a <sleep>
  while (lk->locked) {
    80003fd6:	409c                	lw	a5,0(s1)
    80003fd8:	fbfd                	bnez	a5,80003fce <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003fda:	4785                	li	a5,1
    80003fdc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003fde:	8f1fd0ef          	jal	800018ce <myproc>
    80003fe2:	591c                	lw	a5,48(a0)
    80003fe4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003fe6:	854a                	mv	a0,s2
    80003fe8:	c7ffc0ef          	jal	80000c66 <release>
}
    80003fec:	60e2                	ld	ra,24(sp)
    80003fee:	6442                	ld	s0,16(sp)
    80003ff0:	64a2                	ld	s1,8(sp)
    80003ff2:	6902                	ld	s2,0(sp)
    80003ff4:	6105                	addi	sp,sp,32
    80003ff6:	8082                	ret

0000000080003ff8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003ff8:	1101                	addi	sp,sp,-32
    80003ffa:	ec06                	sd	ra,24(sp)
    80003ffc:	e822                	sd	s0,16(sp)
    80003ffe:	e426                	sd	s1,8(sp)
    80004000:	e04a                	sd	s2,0(sp)
    80004002:	1000                	addi	s0,sp,32
    80004004:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004006:	00850913          	addi	s2,a0,8
    8000400a:	854a                	mv	a0,s2
    8000400c:	bc3fc0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    80004010:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004014:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004018:	8526                	mv	a0,s1
    8000401a:	f6dfd0ef          	jal	80001f86 <wakeup>
  release(&lk->lk);
    8000401e:	854a                	mv	a0,s2
    80004020:	c47fc0ef          	jal	80000c66 <release>
}
    80004024:	60e2                	ld	ra,24(sp)
    80004026:	6442                	ld	s0,16(sp)
    80004028:	64a2                	ld	s1,8(sp)
    8000402a:	6902                	ld	s2,0(sp)
    8000402c:	6105                	addi	sp,sp,32
    8000402e:	8082                	ret

0000000080004030 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004030:	7179                	addi	sp,sp,-48
    80004032:	f406                	sd	ra,40(sp)
    80004034:	f022                	sd	s0,32(sp)
    80004036:	ec26                	sd	s1,24(sp)
    80004038:	e84a                	sd	s2,16(sp)
    8000403a:	1800                	addi	s0,sp,48
    8000403c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000403e:	00850913          	addi	s2,a0,8
    80004042:	854a                	mv	a0,s2
    80004044:	b8bfc0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004048:	409c                	lw	a5,0(s1)
    8000404a:	ef81                	bnez	a5,80004062 <holdingsleep+0x32>
    8000404c:	4481                	li	s1,0
  release(&lk->lk);
    8000404e:	854a                	mv	a0,s2
    80004050:	c17fc0ef          	jal	80000c66 <release>
  return r;
}
    80004054:	8526                	mv	a0,s1
    80004056:	70a2                	ld	ra,40(sp)
    80004058:	7402                	ld	s0,32(sp)
    8000405a:	64e2                	ld	s1,24(sp)
    8000405c:	6942                	ld	s2,16(sp)
    8000405e:	6145                	addi	sp,sp,48
    80004060:	8082                	ret
    80004062:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004064:	0284a983          	lw	s3,40(s1)
    80004068:	867fd0ef          	jal	800018ce <myproc>
    8000406c:	5904                	lw	s1,48(a0)
    8000406e:	413484b3          	sub	s1,s1,s3
    80004072:	0014b493          	seqz	s1,s1
    80004076:	69a2                	ld	s3,8(sp)
    80004078:	bfd9                	j	8000404e <holdingsleep+0x1e>

000000008000407a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000407a:	1141                	addi	sp,sp,-16
    8000407c:	e406                	sd	ra,8(sp)
    8000407e:	e022                	sd	s0,0(sp)
    80004080:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004082:	00003597          	auipc	a1,0x3
    80004086:	4f658593          	addi	a1,a1,1270 # 80007578 <etext+0x578>
    8000408a:	0001e517          	auipc	a0,0x1e
    8000408e:	60650513          	addi	a0,a0,1542 # 80022690 <ftable>
    80004092:	abdfc0ef          	jal	80000b4e <initlock>
}
    80004096:	60a2                	ld	ra,8(sp)
    80004098:	6402                	ld	s0,0(sp)
    8000409a:	0141                	addi	sp,sp,16
    8000409c:	8082                	ret

000000008000409e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000409e:	1101                	addi	sp,sp,-32
    800040a0:	ec06                	sd	ra,24(sp)
    800040a2:	e822                	sd	s0,16(sp)
    800040a4:	e426                	sd	s1,8(sp)
    800040a6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800040a8:	0001e517          	auipc	a0,0x1e
    800040ac:	5e850513          	addi	a0,a0,1512 # 80022690 <ftable>
    800040b0:	b1ffc0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800040b4:	0001e497          	auipc	s1,0x1e
    800040b8:	5f448493          	addi	s1,s1,1524 # 800226a8 <ftable+0x18>
    800040bc:	0001f717          	auipc	a4,0x1f
    800040c0:	58c70713          	addi	a4,a4,1420 # 80023648 <disk>
    if(f->ref == 0){
    800040c4:	40dc                	lw	a5,4(s1)
    800040c6:	cf89                	beqz	a5,800040e0 <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800040c8:	02848493          	addi	s1,s1,40
    800040cc:	fee49ce3          	bne	s1,a4,800040c4 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800040d0:	0001e517          	auipc	a0,0x1e
    800040d4:	5c050513          	addi	a0,a0,1472 # 80022690 <ftable>
    800040d8:	b8ffc0ef          	jal	80000c66 <release>
  return 0;
    800040dc:	4481                	li	s1,0
    800040de:	a809                	j	800040f0 <filealloc+0x52>
      f->ref = 1;
    800040e0:	4785                	li	a5,1
    800040e2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800040e4:	0001e517          	auipc	a0,0x1e
    800040e8:	5ac50513          	addi	a0,a0,1452 # 80022690 <ftable>
    800040ec:	b7bfc0ef          	jal	80000c66 <release>
}
    800040f0:	8526                	mv	a0,s1
    800040f2:	60e2                	ld	ra,24(sp)
    800040f4:	6442                	ld	s0,16(sp)
    800040f6:	64a2                	ld	s1,8(sp)
    800040f8:	6105                	addi	sp,sp,32
    800040fa:	8082                	ret

00000000800040fc <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800040fc:	1101                	addi	sp,sp,-32
    800040fe:	ec06                	sd	ra,24(sp)
    80004100:	e822                	sd	s0,16(sp)
    80004102:	e426                	sd	s1,8(sp)
    80004104:	1000                	addi	s0,sp,32
    80004106:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004108:	0001e517          	auipc	a0,0x1e
    8000410c:	58850513          	addi	a0,a0,1416 # 80022690 <ftable>
    80004110:	abffc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80004114:	40dc                	lw	a5,4(s1)
    80004116:	02f05063          	blez	a5,80004136 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    8000411a:	2785                	addiw	a5,a5,1
    8000411c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000411e:	0001e517          	auipc	a0,0x1e
    80004122:	57250513          	addi	a0,a0,1394 # 80022690 <ftable>
    80004126:	b41fc0ef          	jal	80000c66 <release>
  return f;
}
    8000412a:	8526                	mv	a0,s1
    8000412c:	60e2                	ld	ra,24(sp)
    8000412e:	6442                	ld	s0,16(sp)
    80004130:	64a2                	ld	s1,8(sp)
    80004132:	6105                	addi	sp,sp,32
    80004134:	8082                	ret
    panic("filedup");
    80004136:	00003517          	auipc	a0,0x3
    8000413a:	44a50513          	addi	a0,a0,1098 # 80007580 <etext+0x580>
    8000413e:	ea2fc0ef          	jal	800007e0 <panic>

0000000080004142 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004142:	7139                	addi	sp,sp,-64
    80004144:	fc06                	sd	ra,56(sp)
    80004146:	f822                	sd	s0,48(sp)
    80004148:	f426                	sd	s1,40(sp)
    8000414a:	0080                	addi	s0,sp,64
    8000414c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000414e:	0001e517          	auipc	a0,0x1e
    80004152:	54250513          	addi	a0,a0,1346 # 80022690 <ftable>
    80004156:	a79fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    8000415a:	40dc                	lw	a5,4(s1)
    8000415c:	04f05a63          	blez	a5,800041b0 <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    80004160:	37fd                	addiw	a5,a5,-1
    80004162:	0007871b          	sext.w	a4,a5
    80004166:	c0dc                	sw	a5,4(s1)
    80004168:	04e04e63          	bgtz	a4,800041c4 <fileclose+0x82>
    8000416c:	f04a                	sd	s2,32(sp)
    8000416e:	ec4e                	sd	s3,24(sp)
    80004170:	e852                	sd	s4,16(sp)
    80004172:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004174:	0004a903          	lw	s2,0(s1)
    80004178:	0094ca83          	lbu	s5,9(s1)
    8000417c:	0104ba03          	ld	s4,16(s1)
    80004180:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004184:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004188:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000418c:	0001e517          	auipc	a0,0x1e
    80004190:	50450513          	addi	a0,a0,1284 # 80022690 <ftable>
    80004194:	ad3fc0ef          	jal	80000c66 <release>

  if(ff.type == FD_PIPE){
    80004198:	4785                	li	a5,1
    8000419a:	04f90063          	beq	s2,a5,800041da <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000419e:	3979                	addiw	s2,s2,-2
    800041a0:	4785                	li	a5,1
    800041a2:	0527f563          	bgeu	a5,s2,800041ec <fileclose+0xaa>
    800041a6:	7902                	ld	s2,32(sp)
    800041a8:	69e2                	ld	s3,24(sp)
    800041aa:	6a42                	ld	s4,16(sp)
    800041ac:	6aa2                	ld	s5,8(sp)
    800041ae:	a00d                	j	800041d0 <fileclose+0x8e>
    800041b0:	f04a                	sd	s2,32(sp)
    800041b2:	ec4e                	sd	s3,24(sp)
    800041b4:	e852                	sd	s4,16(sp)
    800041b6:	e456                	sd	s5,8(sp)
    panic("fileclose");
    800041b8:	00003517          	auipc	a0,0x3
    800041bc:	3d050513          	addi	a0,a0,976 # 80007588 <etext+0x588>
    800041c0:	e20fc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    800041c4:	0001e517          	auipc	a0,0x1e
    800041c8:	4cc50513          	addi	a0,a0,1228 # 80022690 <ftable>
    800041cc:	a9bfc0ef          	jal	80000c66 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    800041d0:	70e2                	ld	ra,56(sp)
    800041d2:	7442                	ld	s0,48(sp)
    800041d4:	74a2                	ld	s1,40(sp)
    800041d6:	6121                	addi	sp,sp,64
    800041d8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800041da:	85d6                	mv	a1,s5
    800041dc:	8552                	mv	a0,s4
    800041de:	336000ef          	jal	80004514 <pipeclose>
    800041e2:	7902                	ld	s2,32(sp)
    800041e4:	69e2                	ld	s3,24(sp)
    800041e6:	6a42                	ld	s4,16(sp)
    800041e8:	6aa2                	ld	s5,8(sp)
    800041ea:	b7dd                	j	800041d0 <fileclose+0x8e>
    begin_op();
    800041ec:	b4bff0ef          	jal	80003d36 <begin_op>
    iput(ff.ip);
    800041f0:	854e                	mv	a0,s3
    800041f2:	adcff0ef          	jal	800034ce <iput>
    end_op();
    800041f6:	babff0ef          	jal	80003da0 <end_op>
    800041fa:	7902                	ld	s2,32(sp)
    800041fc:	69e2                	ld	s3,24(sp)
    800041fe:	6a42                	ld	s4,16(sp)
    80004200:	6aa2                	ld	s5,8(sp)
    80004202:	b7f9                	j	800041d0 <fileclose+0x8e>

0000000080004204 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004204:	715d                	addi	sp,sp,-80
    80004206:	e486                	sd	ra,72(sp)
    80004208:	e0a2                	sd	s0,64(sp)
    8000420a:	fc26                	sd	s1,56(sp)
    8000420c:	f44e                	sd	s3,40(sp)
    8000420e:	0880                	addi	s0,sp,80
    80004210:	84aa                	mv	s1,a0
    80004212:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004214:	ebafd0ef          	jal	800018ce <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004218:	409c                	lw	a5,0(s1)
    8000421a:	37f9                	addiw	a5,a5,-2
    8000421c:	4705                	li	a4,1
    8000421e:	04f76063          	bltu	a4,a5,8000425e <filestat+0x5a>
    80004222:	f84a                	sd	s2,48(sp)
    80004224:	892a                	mv	s2,a0
    ilock(f->ip);
    80004226:	6c88                	ld	a0,24(s1)
    80004228:	924ff0ef          	jal	8000334c <ilock>
    stati(f->ip, &st);
    8000422c:	fb840593          	addi	a1,s0,-72
    80004230:	6c88                	ld	a0,24(s1)
    80004232:	c80ff0ef          	jal	800036b2 <stati>
    iunlock(f->ip);
    80004236:	6c88                	ld	a0,24(s1)
    80004238:	9c2ff0ef          	jal	800033fa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000423c:	46e1                	li	a3,24
    8000423e:	fb840613          	addi	a2,s0,-72
    80004242:	85ce                	mv	a1,s3
    80004244:	05093503          	ld	a0,80(s2)
    80004248:	b9afd0ef          	jal	800015e2 <copyout>
    8000424c:	41f5551b          	sraiw	a0,a0,0x1f
    80004250:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004252:	60a6                	ld	ra,72(sp)
    80004254:	6406                	ld	s0,64(sp)
    80004256:	74e2                	ld	s1,56(sp)
    80004258:	79a2                	ld	s3,40(sp)
    8000425a:	6161                	addi	sp,sp,80
    8000425c:	8082                	ret
  return -1;
    8000425e:	557d                	li	a0,-1
    80004260:	bfcd                	j	80004252 <filestat+0x4e>

0000000080004262 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004262:	7179                	addi	sp,sp,-48
    80004264:	f406                	sd	ra,40(sp)
    80004266:	f022                	sd	s0,32(sp)
    80004268:	e84a                	sd	s2,16(sp)
    8000426a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000426c:	00854783          	lbu	a5,8(a0)
    80004270:	cfd1                	beqz	a5,8000430c <fileread+0xaa>
    80004272:	ec26                	sd	s1,24(sp)
    80004274:	e44e                	sd	s3,8(sp)
    80004276:	84aa                	mv	s1,a0
    80004278:	89ae                	mv	s3,a1
    8000427a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000427c:	411c                	lw	a5,0(a0)
    8000427e:	4705                	li	a4,1
    80004280:	04e78363          	beq	a5,a4,800042c6 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004284:	470d                	li	a4,3
    80004286:	04e78763          	beq	a5,a4,800042d4 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000428a:	4709                	li	a4,2
    8000428c:	06e79a63          	bne	a5,a4,80004300 <fileread+0x9e>
    ilock(f->ip);
    80004290:	6d08                	ld	a0,24(a0)
    80004292:	8baff0ef          	jal	8000334c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004296:	874a                	mv	a4,s2
    80004298:	5094                	lw	a3,32(s1)
    8000429a:	864e                	mv	a2,s3
    8000429c:	4585                	li	a1,1
    8000429e:	6c88                	ld	a0,24(s1)
    800042a0:	c3cff0ef          	jal	800036dc <readi>
    800042a4:	892a                	mv	s2,a0
    800042a6:	00a05563          	blez	a0,800042b0 <fileread+0x4e>
      f->off += r;
    800042aa:	509c                	lw	a5,32(s1)
    800042ac:	9fa9                	addw	a5,a5,a0
    800042ae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800042b0:	6c88                	ld	a0,24(s1)
    800042b2:	948ff0ef          	jal	800033fa <iunlock>
    800042b6:	64e2                	ld	s1,24(sp)
    800042b8:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    800042ba:	854a                	mv	a0,s2
    800042bc:	70a2                	ld	ra,40(sp)
    800042be:	7402                	ld	s0,32(sp)
    800042c0:	6942                	ld	s2,16(sp)
    800042c2:	6145                	addi	sp,sp,48
    800042c4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800042c6:	6908                	ld	a0,16(a0)
    800042c8:	388000ef          	jal	80004650 <piperead>
    800042cc:	892a                	mv	s2,a0
    800042ce:	64e2                	ld	s1,24(sp)
    800042d0:	69a2                	ld	s3,8(sp)
    800042d2:	b7e5                	j	800042ba <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800042d4:	02451783          	lh	a5,36(a0)
    800042d8:	03079693          	slli	a3,a5,0x30
    800042dc:	92c1                	srli	a3,a3,0x30
    800042de:	4725                	li	a4,9
    800042e0:	02d76863          	bltu	a4,a3,80004310 <fileread+0xae>
    800042e4:	0792                	slli	a5,a5,0x4
    800042e6:	0001e717          	auipc	a4,0x1e
    800042ea:	30a70713          	addi	a4,a4,778 # 800225f0 <devsw>
    800042ee:	97ba                	add	a5,a5,a4
    800042f0:	639c                	ld	a5,0(a5)
    800042f2:	c39d                	beqz	a5,80004318 <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    800042f4:	4505                	li	a0,1
    800042f6:	9782                	jalr	a5
    800042f8:	892a                	mv	s2,a0
    800042fa:	64e2                	ld	s1,24(sp)
    800042fc:	69a2                	ld	s3,8(sp)
    800042fe:	bf75                	j	800042ba <fileread+0x58>
    panic("fileread");
    80004300:	00003517          	auipc	a0,0x3
    80004304:	29850513          	addi	a0,a0,664 # 80007598 <etext+0x598>
    80004308:	cd8fc0ef          	jal	800007e0 <panic>
    return -1;
    8000430c:	597d                	li	s2,-1
    8000430e:	b775                	j	800042ba <fileread+0x58>
      return -1;
    80004310:	597d                	li	s2,-1
    80004312:	64e2                	ld	s1,24(sp)
    80004314:	69a2                	ld	s3,8(sp)
    80004316:	b755                	j	800042ba <fileread+0x58>
    80004318:	597d                	li	s2,-1
    8000431a:	64e2                	ld	s1,24(sp)
    8000431c:	69a2                	ld	s3,8(sp)
    8000431e:	bf71                	j	800042ba <fileread+0x58>

0000000080004320 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004320:	00954783          	lbu	a5,9(a0)
    80004324:	10078b63          	beqz	a5,8000443a <filewrite+0x11a>
{
    80004328:	715d                	addi	sp,sp,-80
    8000432a:	e486                	sd	ra,72(sp)
    8000432c:	e0a2                	sd	s0,64(sp)
    8000432e:	f84a                	sd	s2,48(sp)
    80004330:	f052                	sd	s4,32(sp)
    80004332:	e85a                	sd	s6,16(sp)
    80004334:	0880                	addi	s0,sp,80
    80004336:	892a                	mv	s2,a0
    80004338:	8b2e                	mv	s6,a1
    8000433a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000433c:	411c                	lw	a5,0(a0)
    8000433e:	4705                	li	a4,1
    80004340:	02e78763          	beq	a5,a4,8000436e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004344:	470d                	li	a4,3
    80004346:	02e78863          	beq	a5,a4,80004376 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000434a:	4709                	li	a4,2
    8000434c:	0ce79c63          	bne	a5,a4,80004424 <filewrite+0x104>
    80004350:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004352:	0ac05863          	blez	a2,80004402 <filewrite+0xe2>
    80004356:	fc26                	sd	s1,56(sp)
    80004358:	ec56                	sd	s5,24(sp)
    8000435a:	e45e                	sd	s7,8(sp)
    8000435c:	e062                	sd	s8,0(sp)
    int i = 0;
    8000435e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004360:	6b85                	lui	s7,0x1
    80004362:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004366:	6c05                	lui	s8,0x1
    80004368:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000436c:	a8b5                	j	800043e8 <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    8000436e:	6908                	ld	a0,16(a0)
    80004370:	1fc000ef          	jal	8000456c <pipewrite>
    80004374:	a04d                	j	80004416 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004376:	02451783          	lh	a5,36(a0)
    8000437a:	03079693          	slli	a3,a5,0x30
    8000437e:	92c1                	srli	a3,a3,0x30
    80004380:	4725                	li	a4,9
    80004382:	0ad76e63          	bltu	a4,a3,8000443e <filewrite+0x11e>
    80004386:	0792                	slli	a5,a5,0x4
    80004388:	0001e717          	auipc	a4,0x1e
    8000438c:	26870713          	addi	a4,a4,616 # 800225f0 <devsw>
    80004390:	97ba                	add	a5,a5,a4
    80004392:	679c                	ld	a5,8(a5)
    80004394:	c7dd                	beqz	a5,80004442 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    80004396:	4505                	li	a0,1
    80004398:	9782                	jalr	a5
    8000439a:	a8b5                	j	80004416 <filewrite+0xf6>
      if(n1 > max)
    8000439c:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800043a0:	997ff0ef          	jal	80003d36 <begin_op>
      ilock(f->ip);
    800043a4:	01893503          	ld	a0,24(s2)
    800043a8:	fa5fe0ef          	jal	8000334c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800043ac:	8756                	mv	a4,s5
    800043ae:	02092683          	lw	a3,32(s2)
    800043b2:	01698633          	add	a2,s3,s6
    800043b6:	4585                	li	a1,1
    800043b8:	01893503          	ld	a0,24(s2)
    800043bc:	c1cff0ef          	jal	800037d8 <writei>
    800043c0:	84aa                	mv	s1,a0
    800043c2:	00a05763          	blez	a0,800043d0 <filewrite+0xb0>
        f->off += r;
    800043c6:	02092783          	lw	a5,32(s2)
    800043ca:	9fa9                	addw	a5,a5,a0
    800043cc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800043d0:	01893503          	ld	a0,24(s2)
    800043d4:	826ff0ef          	jal	800033fa <iunlock>
      end_op();
    800043d8:	9c9ff0ef          	jal	80003da0 <end_op>

      if(r != n1){
    800043dc:	029a9563          	bne	s5,s1,80004406 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    800043e0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800043e4:	0149da63          	bge	s3,s4,800043f8 <filewrite+0xd8>
      int n1 = n - i;
    800043e8:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800043ec:	0004879b          	sext.w	a5,s1
    800043f0:	fafbd6e3          	bge	s7,a5,8000439c <filewrite+0x7c>
    800043f4:	84e2                	mv	s1,s8
    800043f6:	b75d                	j	8000439c <filewrite+0x7c>
    800043f8:	74e2                	ld	s1,56(sp)
    800043fa:	6ae2                	ld	s5,24(sp)
    800043fc:	6ba2                	ld	s7,8(sp)
    800043fe:	6c02                	ld	s8,0(sp)
    80004400:	a039                	j	8000440e <filewrite+0xee>
    int i = 0;
    80004402:	4981                	li	s3,0
    80004404:	a029                	j	8000440e <filewrite+0xee>
    80004406:	74e2                	ld	s1,56(sp)
    80004408:	6ae2                	ld	s5,24(sp)
    8000440a:	6ba2                	ld	s7,8(sp)
    8000440c:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    8000440e:	033a1c63          	bne	s4,s3,80004446 <filewrite+0x126>
    80004412:	8552                	mv	a0,s4
    80004414:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004416:	60a6                	ld	ra,72(sp)
    80004418:	6406                	ld	s0,64(sp)
    8000441a:	7942                	ld	s2,48(sp)
    8000441c:	7a02                	ld	s4,32(sp)
    8000441e:	6b42                	ld	s6,16(sp)
    80004420:	6161                	addi	sp,sp,80
    80004422:	8082                	ret
    80004424:	fc26                	sd	s1,56(sp)
    80004426:	f44e                	sd	s3,40(sp)
    80004428:	ec56                	sd	s5,24(sp)
    8000442a:	e45e                	sd	s7,8(sp)
    8000442c:	e062                	sd	s8,0(sp)
    panic("filewrite");
    8000442e:	00003517          	auipc	a0,0x3
    80004432:	17a50513          	addi	a0,a0,378 # 800075a8 <etext+0x5a8>
    80004436:	baafc0ef          	jal	800007e0 <panic>
    return -1;
    8000443a:	557d                	li	a0,-1
}
    8000443c:	8082                	ret
      return -1;
    8000443e:	557d                	li	a0,-1
    80004440:	bfd9                	j	80004416 <filewrite+0xf6>
    80004442:	557d                	li	a0,-1
    80004444:	bfc9                	j	80004416 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    80004446:	557d                	li	a0,-1
    80004448:	79a2                	ld	s3,40(sp)
    8000444a:	b7f1                	j	80004416 <filewrite+0xf6>

000000008000444c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000444c:	7179                	addi	sp,sp,-48
    8000444e:	f406                	sd	ra,40(sp)
    80004450:	f022                	sd	s0,32(sp)
    80004452:	ec26                	sd	s1,24(sp)
    80004454:	e052                	sd	s4,0(sp)
    80004456:	1800                	addi	s0,sp,48
    80004458:	84aa                	mv	s1,a0
    8000445a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000445c:	0005b023          	sd	zero,0(a1)
    80004460:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004464:	c3bff0ef          	jal	8000409e <filealloc>
    80004468:	e088                	sd	a0,0(s1)
    8000446a:	c549                	beqz	a0,800044f4 <pipealloc+0xa8>
    8000446c:	c33ff0ef          	jal	8000409e <filealloc>
    80004470:	00aa3023          	sd	a0,0(s4)
    80004474:	cd25                	beqz	a0,800044ec <pipealloc+0xa0>
    80004476:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004478:	e86fc0ef          	jal	80000afe <kalloc>
    8000447c:	892a                	mv	s2,a0
    8000447e:	c12d                	beqz	a0,800044e0 <pipealloc+0x94>
    80004480:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004482:	4985                	li	s3,1
    80004484:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004488:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000448c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004490:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004494:	00003597          	auipc	a1,0x3
    80004498:	12458593          	addi	a1,a1,292 # 800075b8 <etext+0x5b8>
    8000449c:	eb2fc0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    800044a0:	609c                	ld	a5,0(s1)
    800044a2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800044a6:	609c                	ld	a5,0(s1)
    800044a8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800044ac:	609c                	ld	a5,0(s1)
    800044ae:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800044b2:	609c                	ld	a5,0(s1)
    800044b4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800044b8:	000a3783          	ld	a5,0(s4)
    800044bc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800044c0:	000a3783          	ld	a5,0(s4)
    800044c4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800044c8:	000a3783          	ld	a5,0(s4)
    800044cc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800044d0:	000a3783          	ld	a5,0(s4)
    800044d4:	0127b823          	sd	s2,16(a5)
  return 0;
    800044d8:	4501                	li	a0,0
    800044da:	6942                	ld	s2,16(sp)
    800044dc:	69a2                	ld	s3,8(sp)
    800044de:	a01d                	j	80004504 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800044e0:	6088                	ld	a0,0(s1)
    800044e2:	c119                	beqz	a0,800044e8 <pipealloc+0x9c>
    800044e4:	6942                	ld	s2,16(sp)
    800044e6:	a029                	j	800044f0 <pipealloc+0xa4>
    800044e8:	6942                	ld	s2,16(sp)
    800044ea:	a029                	j	800044f4 <pipealloc+0xa8>
    800044ec:	6088                	ld	a0,0(s1)
    800044ee:	c10d                	beqz	a0,80004510 <pipealloc+0xc4>
    fileclose(*f0);
    800044f0:	c53ff0ef          	jal	80004142 <fileclose>
  if(*f1)
    800044f4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800044f8:	557d                	li	a0,-1
  if(*f1)
    800044fa:	c789                	beqz	a5,80004504 <pipealloc+0xb8>
    fileclose(*f1);
    800044fc:	853e                	mv	a0,a5
    800044fe:	c45ff0ef          	jal	80004142 <fileclose>
  return -1;
    80004502:	557d                	li	a0,-1
}
    80004504:	70a2                	ld	ra,40(sp)
    80004506:	7402                	ld	s0,32(sp)
    80004508:	64e2                	ld	s1,24(sp)
    8000450a:	6a02                	ld	s4,0(sp)
    8000450c:	6145                	addi	sp,sp,48
    8000450e:	8082                	ret
  return -1;
    80004510:	557d                	li	a0,-1
    80004512:	bfcd                	j	80004504 <pipealloc+0xb8>

0000000080004514 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004514:	1101                	addi	sp,sp,-32
    80004516:	ec06                	sd	ra,24(sp)
    80004518:	e822                	sd	s0,16(sp)
    8000451a:	e426                	sd	s1,8(sp)
    8000451c:	e04a                	sd	s2,0(sp)
    8000451e:	1000                	addi	s0,sp,32
    80004520:	84aa                	mv	s1,a0
    80004522:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004524:	eaafc0ef          	jal	80000bce <acquire>
  if(writable){
    80004528:	02090763          	beqz	s2,80004556 <pipeclose+0x42>
    pi->writeopen = 0;
    8000452c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004530:	21848513          	addi	a0,s1,536
    80004534:	a53fd0ef          	jal	80001f86 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004538:	2204b783          	ld	a5,544(s1)
    8000453c:	e785                	bnez	a5,80004564 <pipeclose+0x50>
    release(&pi->lock);
    8000453e:	8526                	mv	a0,s1
    80004540:	f26fc0ef          	jal	80000c66 <release>
    kfree((char*)pi);
    80004544:	8526                	mv	a0,s1
    80004546:	cd6fc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    8000454a:	60e2                	ld	ra,24(sp)
    8000454c:	6442                	ld	s0,16(sp)
    8000454e:	64a2                	ld	s1,8(sp)
    80004550:	6902                	ld	s2,0(sp)
    80004552:	6105                	addi	sp,sp,32
    80004554:	8082                	ret
    pi->readopen = 0;
    80004556:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000455a:	21c48513          	addi	a0,s1,540
    8000455e:	a29fd0ef          	jal	80001f86 <wakeup>
    80004562:	bfd9                	j	80004538 <pipeclose+0x24>
    release(&pi->lock);
    80004564:	8526                	mv	a0,s1
    80004566:	f00fc0ef          	jal	80000c66 <release>
}
    8000456a:	b7c5                	j	8000454a <pipeclose+0x36>

000000008000456c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000456c:	711d                	addi	sp,sp,-96
    8000456e:	ec86                	sd	ra,88(sp)
    80004570:	e8a2                	sd	s0,80(sp)
    80004572:	e4a6                	sd	s1,72(sp)
    80004574:	e0ca                	sd	s2,64(sp)
    80004576:	fc4e                	sd	s3,56(sp)
    80004578:	f852                	sd	s4,48(sp)
    8000457a:	f456                	sd	s5,40(sp)
    8000457c:	1080                	addi	s0,sp,96
    8000457e:	84aa                	mv	s1,a0
    80004580:	8aae                	mv	s5,a1
    80004582:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004584:	b4afd0ef          	jal	800018ce <myproc>
    80004588:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000458a:	8526                	mv	a0,s1
    8000458c:	e42fc0ef          	jal	80000bce <acquire>
  while(i < n){
    80004590:	0b405a63          	blez	s4,80004644 <pipewrite+0xd8>
    80004594:	f05a                	sd	s6,32(sp)
    80004596:	ec5e                	sd	s7,24(sp)
    80004598:	e862                	sd	s8,16(sp)
  int i = 0;
    8000459a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000459c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000459e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800045a2:	21c48b93          	addi	s7,s1,540
    800045a6:	a81d                	j	800045dc <pipewrite+0x70>
      release(&pi->lock);
    800045a8:	8526                	mv	a0,s1
    800045aa:	ebcfc0ef          	jal	80000c66 <release>
      return -1;
    800045ae:	597d                	li	s2,-1
    800045b0:	7b02                	ld	s6,32(sp)
    800045b2:	6be2                	ld	s7,24(sp)
    800045b4:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800045b6:	854a                	mv	a0,s2
    800045b8:	60e6                	ld	ra,88(sp)
    800045ba:	6446                	ld	s0,80(sp)
    800045bc:	64a6                	ld	s1,72(sp)
    800045be:	6906                	ld	s2,64(sp)
    800045c0:	79e2                	ld	s3,56(sp)
    800045c2:	7a42                	ld	s4,48(sp)
    800045c4:	7aa2                	ld	s5,40(sp)
    800045c6:	6125                	addi	sp,sp,96
    800045c8:	8082                	ret
      wakeup(&pi->nread);
    800045ca:	8562                	mv	a0,s8
    800045cc:	9bbfd0ef          	jal	80001f86 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800045d0:	85a6                	mv	a1,s1
    800045d2:	855e                	mv	a0,s7
    800045d4:	967fd0ef          	jal	80001f3a <sleep>
  while(i < n){
    800045d8:	05495b63          	bge	s2,s4,8000462e <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    800045dc:	2204a783          	lw	a5,544(s1)
    800045e0:	d7e1                	beqz	a5,800045a8 <pipewrite+0x3c>
    800045e2:	854e                	mv	a0,s3
    800045e4:	b8ffd0ef          	jal	80002172 <killed>
    800045e8:	f161                	bnez	a0,800045a8 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800045ea:	2184a783          	lw	a5,536(s1)
    800045ee:	21c4a703          	lw	a4,540(s1)
    800045f2:	2007879b          	addiw	a5,a5,512
    800045f6:	fcf70ae3          	beq	a4,a5,800045ca <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800045fa:	4685                	li	a3,1
    800045fc:	01590633          	add	a2,s2,s5
    80004600:	faf40593          	addi	a1,s0,-81
    80004604:	0509b503          	ld	a0,80(s3)
    80004608:	8befd0ef          	jal	800016c6 <copyin>
    8000460c:	03650e63          	beq	a0,s6,80004648 <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004610:	21c4a783          	lw	a5,540(s1)
    80004614:	0017871b          	addiw	a4,a5,1
    80004618:	20e4ae23          	sw	a4,540(s1)
    8000461c:	1ff7f793          	andi	a5,a5,511
    80004620:	97a6                	add	a5,a5,s1
    80004622:	faf44703          	lbu	a4,-81(s0)
    80004626:	00e78c23          	sb	a4,24(a5)
      i++;
    8000462a:	2905                	addiw	s2,s2,1
    8000462c:	b775                	j	800045d8 <pipewrite+0x6c>
    8000462e:	7b02                	ld	s6,32(sp)
    80004630:	6be2                	ld	s7,24(sp)
    80004632:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80004634:	21848513          	addi	a0,s1,536
    80004638:	94ffd0ef          	jal	80001f86 <wakeup>
  release(&pi->lock);
    8000463c:	8526                	mv	a0,s1
    8000463e:	e28fc0ef          	jal	80000c66 <release>
  return i;
    80004642:	bf95                	j	800045b6 <pipewrite+0x4a>
  int i = 0;
    80004644:	4901                	li	s2,0
    80004646:	b7fd                	j	80004634 <pipewrite+0xc8>
    80004648:	7b02                	ld	s6,32(sp)
    8000464a:	6be2                	ld	s7,24(sp)
    8000464c:	6c42                	ld	s8,16(sp)
    8000464e:	b7dd                	j	80004634 <pipewrite+0xc8>

0000000080004650 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004650:	715d                	addi	sp,sp,-80
    80004652:	e486                	sd	ra,72(sp)
    80004654:	e0a2                	sd	s0,64(sp)
    80004656:	fc26                	sd	s1,56(sp)
    80004658:	f84a                	sd	s2,48(sp)
    8000465a:	f44e                	sd	s3,40(sp)
    8000465c:	f052                	sd	s4,32(sp)
    8000465e:	ec56                	sd	s5,24(sp)
    80004660:	0880                	addi	s0,sp,80
    80004662:	84aa                	mv	s1,a0
    80004664:	892e                	mv	s2,a1
    80004666:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004668:	a66fd0ef          	jal	800018ce <myproc>
    8000466c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000466e:	8526                	mv	a0,s1
    80004670:	d5efc0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004674:	2184a703          	lw	a4,536(s1)
    80004678:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000467c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004680:	02f71563          	bne	a4,a5,800046aa <piperead+0x5a>
    80004684:	2244a783          	lw	a5,548(s1)
    80004688:	cb85                	beqz	a5,800046b8 <piperead+0x68>
    if(killed(pr)){
    8000468a:	8552                	mv	a0,s4
    8000468c:	ae7fd0ef          	jal	80002172 <killed>
    80004690:	ed19                	bnez	a0,800046ae <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004692:	85a6                	mv	a1,s1
    80004694:	854e                	mv	a0,s3
    80004696:	8a5fd0ef          	jal	80001f3a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000469a:	2184a703          	lw	a4,536(s1)
    8000469e:	21c4a783          	lw	a5,540(s1)
    800046a2:	fef701e3          	beq	a4,a5,80004684 <piperead+0x34>
    800046a6:	e85a                	sd	s6,16(sp)
    800046a8:	a809                	j	800046ba <piperead+0x6a>
    800046aa:	e85a                	sd	s6,16(sp)
    800046ac:	a039                	j	800046ba <piperead+0x6a>
      release(&pi->lock);
    800046ae:	8526                	mv	a0,s1
    800046b0:	db6fc0ef          	jal	80000c66 <release>
      return -1;
    800046b4:	59fd                	li	s3,-1
    800046b6:	a8b9                	j	80004714 <piperead+0xc4>
    800046b8:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046ba:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800046bc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046be:	05505363          	blez	s5,80004704 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800046c2:	2184a783          	lw	a5,536(s1)
    800046c6:	21c4a703          	lw	a4,540(s1)
    800046ca:	02f70d63          	beq	a4,a5,80004704 <piperead+0xb4>
    ch = pi->data[pi->nread % PIPESIZE];
    800046ce:	1ff7f793          	andi	a5,a5,511
    800046d2:	97a6                	add	a5,a5,s1
    800046d4:	0187c783          	lbu	a5,24(a5)
    800046d8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    800046dc:	4685                	li	a3,1
    800046de:	fbf40613          	addi	a2,s0,-65
    800046e2:	85ca                	mv	a1,s2
    800046e4:	050a3503          	ld	a0,80(s4)
    800046e8:	efbfc0ef          	jal	800015e2 <copyout>
    800046ec:	03650e63          	beq	a0,s6,80004728 <piperead+0xd8>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    800046f0:	2184a783          	lw	a5,536(s1)
    800046f4:	2785                	addiw	a5,a5,1
    800046f6:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800046fa:	2985                	addiw	s3,s3,1
    800046fc:	0905                	addi	s2,s2,1
    800046fe:	fd3a92e3          	bne	s5,s3,800046c2 <piperead+0x72>
    80004702:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004704:	21c48513          	addi	a0,s1,540
    80004708:	87ffd0ef          	jal	80001f86 <wakeup>
  release(&pi->lock);
    8000470c:	8526                	mv	a0,s1
    8000470e:	d58fc0ef          	jal	80000c66 <release>
    80004712:	6b42                	ld	s6,16(sp)
  return i;
}
    80004714:	854e                	mv	a0,s3
    80004716:	60a6                	ld	ra,72(sp)
    80004718:	6406                	ld	s0,64(sp)
    8000471a:	74e2                	ld	s1,56(sp)
    8000471c:	7942                	ld	s2,48(sp)
    8000471e:	79a2                	ld	s3,40(sp)
    80004720:	7a02                	ld	s4,32(sp)
    80004722:	6ae2                	ld	s5,24(sp)
    80004724:	6161                	addi	sp,sp,80
    80004726:	8082                	ret
      if(i == 0)
    80004728:	fc099ee3          	bnez	s3,80004704 <piperead+0xb4>
        i = -1;
    8000472c:	89aa                	mv	s3,a0
    8000472e:	bfd9                	j	80004704 <piperead+0xb4>

0000000080004730 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004730:	1141                	addi	sp,sp,-16
    80004732:	e422                	sd	s0,8(sp)
    80004734:	0800                	addi	s0,sp,16
    80004736:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004738:	8905                	andi	a0,a0,1
    8000473a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000473c:	8b89                	andi	a5,a5,2
    8000473e:	c399                	beqz	a5,80004744 <flags2perm+0x14>
      perm |= PTE_W;
    80004740:	00456513          	ori	a0,a0,4
    return perm;
}
    80004744:	6422                	ld	s0,8(sp)
    80004746:	0141                	addi	sp,sp,16
    80004748:	8082                	ret

000000008000474a <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    8000474a:	df010113          	addi	sp,sp,-528
    8000474e:	20113423          	sd	ra,520(sp)
    80004752:	20813023          	sd	s0,512(sp)
    80004756:	ffa6                	sd	s1,504(sp)
    80004758:	fbca                	sd	s2,496(sp)
    8000475a:	0c00                	addi	s0,sp,528
    8000475c:	892a                	mv	s2,a0
    8000475e:	dea43c23          	sd	a0,-520(s0)
    80004762:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004766:	968fd0ef          	jal	800018ce <myproc>
    8000476a:	84aa                	mv	s1,a0

  begin_op();
    8000476c:	dcaff0ef          	jal	80003d36 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004770:	854a                	mv	a0,s2
    80004772:	bf0ff0ef          	jal	80003b62 <namei>
    80004776:	c931                	beqz	a0,800047ca <kexec+0x80>
    80004778:	f3d2                	sd	s4,480(sp)
    8000477a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000477c:	bd1fe0ef          	jal	8000334c <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004780:	04000713          	li	a4,64
    80004784:	4681                	li	a3,0
    80004786:	e5040613          	addi	a2,s0,-432
    8000478a:	4581                	li	a1,0
    8000478c:	8552                	mv	a0,s4
    8000478e:	f4ffe0ef          	jal	800036dc <readi>
    80004792:	04000793          	li	a5,64
    80004796:	00f51a63          	bne	a0,a5,800047aa <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    8000479a:	e5042703          	lw	a4,-432(s0)
    8000479e:	464c47b7          	lui	a5,0x464c4
    800047a2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800047a6:	02f70663          	beq	a4,a5,800047d2 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800047aa:	8552                	mv	a0,s4
    800047ac:	dabfe0ef          	jal	80003556 <iunlockput>
    end_op();
    800047b0:	df0ff0ef          	jal	80003da0 <end_op>
  }
  return -1;
    800047b4:	557d                	li	a0,-1
    800047b6:	7a1e                	ld	s4,480(sp)
}
    800047b8:	20813083          	ld	ra,520(sp)
    800047bc:	20013403          	ld	s0,512(sp)
    800047c0:	74fe                	ld	s1,504(sp)
    800047c2:	795e                	ld	s2,496(sp)
    800047c4:	21010113          	addi	sp,sp,528
    800047c8:	8082                	ret
    end_op();
    800047ca:	dd6ff0ef          	jal	80003da0 <end_op>
    return -1;
    800047ce:	557d                	li	a0,-1
    800047d0:	b7e5                	j	800047b8 <kexec+0x6e>
    800047d2:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    800047d4:	8526                	mv	a0,s1
    800047d6:	9fefd0ef          	jal	800019d4 <proc_pagetable>
    800047da:	8b2a                	mv	s6,a0
    800047dc:	2c050b63          	beqz	a0,80004ab2 <kexec+0x368>
    800047e0:	f7ce                	sd	s3,488(sp)
    800047e2:	efd6                	sd	s5,472(sp)
    800047e4:	e7de                	sd	s7,456(sp)
    800047e6:	e3e2                	sd	s8,448(sp)
    800047e8:	ff66                	sd	s9,440(sp)
    800047ea:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800047ec:	e7042d03          	lw	s10,-400(s0)
    800047f0:	e8845783          	lhu	a5,-376(s0)
    800047f4:	12078963          	beqz	a5,80004926 <kexec+0x1dc>
    800047f8:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800047fa:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800047fc:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800047fe:	6c85                	lui	s9,0x1
    80004800:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004804:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004808:	6a85                	lui	s5,0x1
    8000480a:	a085                	j	8000486a <kexec+0x120>
      panic("loadseg: address should exist");
    8000480c:	00003517          	auipc	a0,0x3
    80004810:	db450513          	addi	a0,a0,-588 # 800075c0 <etext+0x5c0>
    80004814:	fcdfb0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    80004818:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000481a:	8726                	mv	a4,s1
    8000481c:	012c06bb          	addw	a3,s8,s2
    80004820:	4581                	li	a1,0
    80004822:	8552                	mv	a0,s4
    80004824:	eb9fe0ef          	jal	800036dc <readi>
    80004828:	2501                	sext.w	a0,a0
    8000482a:	24a49a63          	bne	s1,a0,80004a7e <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    8000482e:	012a893b          	addw	s2,s5,s2
    80004832:	03397363          	bgeu	s2,s3,80004858 <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    80004836:	02091593          	slli	a1,s2,0x20
    8000483a:	9181                	srli	a1,a1,0x20
    8000483c:	95de                	add	a1,a1,s7
    8000483e:	855a                	mv	a0,s6
    80004840:	f70fc0ef          	jal	80000fb0 <walkaddr>
    80004844:	862a                	mv	a2,a0
    if(pa == 0)
    80004846:	d179                	beqz	a0,8000480c <kexec+0xc2>
    if(sz - i < PGSIZE)
    80004848:	412984bb          	subw	s1,s3,s2
    8000484c:	0004879b          	sext.w	a5,s1
    80004850:	fcfcf4e3          	bgeu	s9,a5,80004818 <kexec+0xce>
    80004854:	84d6                	mv	s1,s5
    80004856:	b7c9                	j	80004818 <kexec+0xce>
    sz = sz1;
    80004858:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000485c:	2d85                	addiw	s11,s11,1
    8000485e:	038d0d1b          	addiw	s10,s10,56 # 1038 <_entry-0x7fffefc8>
    80004862:	e8845783          	lhu	a5,-376(s0)
    80004866:	08fdd063          	bge	s11,a5,800048e6 <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000486a:	2d01                	sext.w	s10,s10
    8000486c:	03800713          	li	a4,56
    80004870:	86ea                	mv	a3,s10
    80004872:	e1840613          	addi	a2,s0,-488
    80004876:	4581                	li	a1,0
    80004878:	8552                	mv	a0,s4
    8000487a:	e63fe0ef          	jal	800036dc <readi>
    8000487e:	03800793          	li	a5,56
    80004882:	1cf51663          	bne	a0,a5,80004a4e <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80004886:	e1842783          	lw	a5,-488(s0)
    8000488a:	4705                	li	a4,1
    8000488c:	fce798e3          	bne	a5,a4,8000485c <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004890:	e4043483          	ld	s1,-448(s0)
    80004894:	e3843783          	ld	a5,-456(s0)
    80004898:	1af4ef63          	bltu	s1,a5,80004a56 <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000489c:	e2843783          	ld	a5,-472(s0)
    800048a0:	94be                	add	s1,s1,a5
    800048a2:	1af4ee63          	bltu	s1,a5,80004a5e <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    800048a6:	df043703          	ld	a4,-528(s0)
    800048aa:	8ff9                	and	a5,a5,a4
    800048ac:	1a079d63          	bnez	a5,80004a66 <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800048b0:	e1c42503          	lw	a0,-484(s0)
    800048b4:	e7dff0ef          	jal	80004730 <flags2perm>
    800048b8:	86aa                	mv	a3,a0
    800048ba:	8626                	mv	a2,s1
    800048bc:	85ca                	mv	a1,s2
    800048be:	855a                	mv	a0,s6
    800048c0:	9c9fc0ef          	jal	80001288 <uvmalloc>
    800048c4:	e0a43423          	sd	a0,-504(s0)
    800048c8:	1a050363          	beqz	a0,80004a6e <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800048cc:	e2843b83          	ld	s7,-472(s0)
    800048d0:	e2042c03          	lw	s8,-480(s0)
    800048d4:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800048d8:	00098463          	beqz	s3,800048e0 <kexec+0x196>
    800048dc:	4901                	li	s2,0
    800048de:	bfa1                	j	80004836 <kexec+0xec>
    sz = sz1;
    800048e0:	e0843903          	ld	s2,-504(s0)
    800048e4:	bfa5                	j	8000485c <kexec+0x112>
    800048e6:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    800048e8:	8552                	mv	a0,s4
    800048ea:	c6dfe0ef          	jal	80003556 <iunlockput>
  end_op();
    800048ee:	cb2ff0ef          	jal	80003da0 <end_op>
  p = myproc();
    800048f2:	fddfc0ef          	jal	800018ce <myproc>
    800048f6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800048f8:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800048fc:	6985                	lui	s3,0x1
    800048fe:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004900:	99ca                	add	s3,s3,s2
    80004902:	77fd                	lui	a5,0xfffff
    80004904:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004908:	4691                	li	a3,4
    8000490a:	6609                	lui	a2,0x2
    8000490c:	964e                	add	a2,a2,s3
    8000490e:	85ce                	mv	a1,s3
    80004910:	855a                	mv	a0,s6
    80004912:	977fc0ef          	jal	80001288 <uvmalloc>
    80004916:	892a                	mv	s2,a0
    80004918:	e0a43423          	sd	a0,-504(s0)
    8000491c:	e519                	bnez	a0,8000492a <kexec+0x1e0>
  if(pagetable)
    8000491e:	e1343423          	sd	s3,-504(s0)
    80004922:	4a01                	li	s4,0
    80004924:	aab1                	j	80004a80 <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004926:	4901                	li	s2,0
    80004928:	b7c1                	j	800048e8 <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    8000492a:	75f9                	lui	a1,0xffffe
    8000492c:	95aa                	add	a1,a1,a0
    8000492e:	855a                	mv	a0,s6
    80004930:	b2ffc0ef          	jal	8000145e <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004934:	7bfd                	lui	s7,0xfffff
    80004936:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004938:	e0043783          	ld	a5,-512(s0)
    8000493c:	6388                	ld	a0,0(a5)
    8000493e:	cd39                	beqz	a0,8000499c <kexec+0x252>
    80004940:	e9040993          	addi	s3,s0,-368
    80004944:	f9040c13          	addi	s8,s0,-112
    80004948:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000494a:	cc8fc0ef          	jal	80000e12 <strlen>
    8000494e:	0015079b          	addiw	a5,a0,1
    80004952:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004956:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000495a:	11796e63          	bltu	s2,s7,80004a76 <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000495e:	e0043d03          	ld	s10,-512(s0)
    80004962:	000d3a03          	ld	s4,0(s10)
    80004966:	8552                	mv	a0,s4
    80004968:	caafc0ef          	jal	80000e12 <strlen>
    8000496c:	0015069b          	addiw	a3,a0,1
    80004970:	8652                	mv	a2,s4
    80004972:	85ca                	mv	a1,s2
    80004974:	855a                	mv	a0,s6
    80004976:	c6dfc0ef          	jal	800015e2 <copyout>
    8000497a:	10054063          	bltz	a0,80004a7a <kexec+0x330>
    ustack[argc] = sp;
    8000497e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004982:	0485                	addi	s1,s1,1
    80004984:	008d0793          	addi	a5,s10,8
    80004988:	e0f43023          	sd	a5,-512(s0)
    8000498c:	008d3503          	ld	a0,8(s10)
    80004990:	c909                	beqz	a0,800049a2 <kexec+0x258>
    if(argc >= MAXARG)
    80004992:	09a1                	addi	s3,s3,8
    80004994:	fb899be3          	bne	s3,s8,8000494a <kexec+0x200>
  ip = 0;
    80004998:	4a01                	li	s4,0
    8000499a:	a0dd                	j	80004a80 <kexec+0x336>
  sp = sz;
    8000499c:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    800049a0:	4481                	li	s1,0
  ustack[argc] = 0;
    800049a2:	00349793          	slli	a5,s1,0x3
    800049a6:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdb808>
    800049aa:	97a2                	add	a5,a5,s0
    800049ac:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800049b0:	00148693          	addi	a3,s1,1
    800049b4:	068e                	slli	a3,a3,0x3
    800049b6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800049ba:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800049be:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800049c2:	f5796ee3          	bltu	s2,s7,8000491e <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800049c6:	e9040613          	addi	a2,s0,-368
    800049ca:	85ca                	mv	a1,s2
    800049cc:	855a                	mv	a0,s6
    800049ce:	c15fc0ef          	jal	800015e2 <copyout>
    800049d2:	0e054263          	bltz	a0,80004ab6 <kexec+0x36c>
  p->trapframe->a1 = sp;
    800049d6:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800049da:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800049de:	df843783          	ld	a5,-520(s0)
    800049e2:	0007c703          	lbu	a4,0(a5)
    800049e6:	cf11                	beqz	a4,80004a02 <kexec+0x2b8>
    800049e8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800049ea:	02f00693          	li	a3,47
    800049ee:	a039                	j	800049fc <kexec+0x2b2>
      last = s+1;
    800049f0:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800049f4:	0785                	addi	a5,a5,1
    800049f6:	fff7c703          	lbu	a4,-1(a5)
    800049fa:	c701                	beqz	a4,80004a02 <kexec+0x2b8>
    if(*s == '/')
    800049fc:	fed71ce3          	bne	a4,a3,800049f4 <kexec+0x2aa>
    80004a00:	bfc5                	j	800049f0 <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    80004a02:	4641                	li	a2,16
    80004a04:	df843583          	ld	a1,-520(s0)
    80004a08:	158a8513          	addi	a0,s5,344
    80004a0c:	bd4fc0ef          	jal	80000de0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004a10:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004a14:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004a18:	e0843783          	ld	a5,-504(s0)
    80004a1c:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    80004a20:	058ab783          	ld	a5,88(s5)
    80004a24:	e6843703          	ld	a4,-408(s0)
    80004a28:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004a2a:	058ab783          	ld	a5,88(s5)
    80004a2e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004a32:	85e6                	mv	a1,s9
    80004a34:	824fd0ef          	jal	80001a58 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004a38:	0004851b          	sext.w	a0,s1
    80004a3c:	79be                	ld	s3,488(sp)
    80004a3e:	7a1e                	ld	s4,480(sp)
    80004a40:	6afe                	ld	s5,472(sp)
    80004a42:	6b5e                	ld	s6,464(sp)
    80004a44:	6bbe                	ld	s7,456(sp)
    80004a46:	6c1e                	ld	s8,448(sp)
    80004a48:	7cfa                	ld	s9,440(sp)
    80004a4a:	7d5a                	ld	s10,432(sp)
    80004a4c:	b3b5                	j	800047b8 <kexec+0x6e>
    80004a4e:	e1243423          	sd	s2,-504(s0)
    80004a52:	7dba                	ld	s11,424(sp)
    80004a54:	a035                	j	80004a80 <kexec+0x336>
    80004a56:	e1243423          	sd	s2,-504(s0)
    80004a5a:	7dba                	ld	s11,424(sp)
    80004a5c:	a015                	j	80004a80 <kexec+0x336>
    80004a5e:	e1243423          	sd	s2,-504(s0)
    80004a62:	7dba                	ld	s11,424(sp)
    80004a64:	a831                	j	80004a80 <kexec+0x336>
    80004a66:	e1243423          	sd	s2,-504(s0)
    80004a6a:	7dba                	ld	s11,424(sp)
    80004a6c:	a811                	j	80004a80 <kexec+0x336>
    80004a6e:	e1243423          	sd	s2,-504(s0)
    80004a72:	7dba                	ld	s11,424(sp)
    80004a74:	a031                	j	80004a80 <kexec+0x336>
  ip = 0;
    80004a76:	4a01                	li	s4,0
    80004a78:	a021                	j	80004a80 <kexec+0x336>
    80004a7a:	4a01                	li	s4,0
  if(pagetable)
    80004a7c:	a011                	j	80004a80 <kexec+0x336>
    80004a7e:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004a80:	e0843583          	ld	a1,-504(s0)
    80004a84:	855a                	mv	a0,s6
    80004a86:	fd3fc0ef          	jal	80001a58 <proc_freepagetable>
  return -1;
    80004a8a:	557d                	li	a0,-1
  if(ip){
    80004a8c:	000a1b63          	bnez	s4,80004aa2 <kexec+0x358>
    80004a90:	79be                	ld	s3,488(sp)
    80004a92:	7a1e                	ld	s4,480(sp)
    80004a94:	6afe                	ld	s5,472(sp)
    80004a96:	6b5e                	ld	s6,464(sp)
    80004a98:	6bbe                	ld	s7,456(sp)
    80004a9a:	6c1e                	ld	s8,448(sp)
    80004a9c:	7cfa                	ld	s9,440(sp)
    80004a9e:	7d5a                	ld	s10,432(sp)
    80004aa0:	bb21                	j	800047b8 <kexec+0x6e>
    80004aa2:	79be                	ld	s3,488(sp)
    80004aa4:	6afe                	ld	s5,472(sp)
    80004aa6:	6b5e                	ld	s6,464(sp)
    80004aa8:	6bbe                	ld	s7,456(sp)
    80004aaa:	6c1e                	ld	s8,448(sp)
    80004aac:	7cfa                	ld	s9,440(sp)
    80004aae:	7d5a                	ld	s10,432(sp)
    80004ab0:	b9ed                	j	800047aa <kexec+0x60>
    80004ab2:	6b5e                	ld	s6,464(sp)
    80004ab4:	b9dd                	j	800047aa <kexec+0x60>
  sz = sz1;
    80004ab6:	e0843983          	ld	s3,-504(s0)
    80004aba:	b595                	j	8000491e <kexec+0x1d4>

0000000080004abc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004abc:	7179                	addi	sp,sp,-48
    80004abe:	f406                	sd	ra,40(sp)
    80004ac0:	f022                	sd	s0,32(sp)
    80004ac2:	ec26                	sd	s1,24(sp)
    80004ac4:	e84a                	sd	s2,16(sp)
    80004ac6:	1800                	addi	s0,sp,48
    80004ac8:	892e                	mv	s2,a1
    80004aca:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004acc:	fdc40593          	addi	a1,s0,-36
    80004ad0:	dd5fd0ef          	jal	800028a4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ad4:	fdc42703          	lw	a4,-36(s0)
    80004ad8:	47bd                	li	a5,15
    80004ada:	02e7e963          	bltu	a5,a4,80004b0c <argfd+0x50>
    80004ade:	df1fc0ef          	jal	800018ce <myproc>
    80004ae2:	fdc42703          	lw	a4,-36(s0)
    80004ae6:	01a70793          	addi	a5,a4,26
    80004aea:	078e                	slli	a5,a5,0x3
    80004aec:	953e                	add	a0,a0,a5
    80004aee:	611c                	ld	a5,0(a0)
    80004af0:	c385                	beqz	a5,80004b10 <argfd+0x54>
    return -1;
  if(pfd)
    80004af2:	00090463          	beqz	s2,80004afa <argfd+0x3e>
    *pfd = fd;
    80004af6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004afa:	4501                	li	a0,0
  if(pf)
    80004afc:	c091                	beqz	s1,80004b00 <argfd+0x44>
    *pf = f;
    80004afe:	e09c                	sd	a5,0(s1)
}
    80004b00:	70a2                	ld	ra,40(sp)
    80004b02:	7402                	ld	s0,32(sp)
    80004b04:	64e2                	ld	s1,24(sp)
    80004b06:	6942                	ld	s2,16(sp)
    80004b08:	6145                	addi	sp,sp,48
    80004b0a:	8082                	ret
    return -1;
    80004b0c:	557d                	li	a0,-1
    80004b0e:	bfcd                	j	80004b00 <argfd+0x44>
    80004b10:	557d                	li	a0,-1
    80004b12:	b7fd                	j	80004b00 <argfd+0x44>

0000000080004b14 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004b14:	1101                	addi	sp,sp,-32
    80004b16:	ec06                	sd	ra,24(sp)
    80004b18:	e822                	sd	s0,16(sp)
    80004b1a:	e426                	sd	s1,8(sp)
    80004b1c:	1000                	addi	s0,sp,32
    80004b1e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004b20:	daffc0ef          	jal	800018ce <myproc>
    80004b24:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004b26:	0d050793          	addi	a5,a0,208
    80004b2a:	4501                	li	a0,0
    80004b2c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004b2e:	6398                	ld	a4,0(a5)
    80004b30:	cb19                	beqz	a4,80004b46 <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004b32:	2505                	addiw	a0,a0,1
    80004b34:	07a1                	addi	a5,a5,8
    80004b36:	fed51ce3          	bne	a0,a3,80004b2e <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004b3a:	557d                	li	a0,-1
}
    80004b3c:	60e2                	ld	ra,24(sp)
    80004b3e:	6442                	ld	s0,16(sp)
    80004b40:	64a2                	ld	s1,8(sp)
    80004b42:	6105                	addi	sp,sp,32
    80004b44:	8082                	ret
      p->ofile[fd] = f;
    80004b46:	01a50793          	addi	a5,a0,26
    80004b4a:	078e                	slli	a5,a5,0x3
    80004b4c:	963e                	add	a2,a2,a5
    80004b4e:	e204                	sd	s1,0(a2)
      return fd;
    80004b50:	b7f5                	j	80004b3c <fdalloc+0x28>

0000000080004b52 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004b52:	715d                	addi	sp,sp,-80
    80004b54:	e486                	sd	ra,72(sp)
    80004b56:	e0a2                	sd	s0,64(sp)
    80004b58:	fc26                	sd	s1,56(sp)
    80004b5a:	f84a                	sd	s2,48(sp)
    80004b5c:	f44e                	sd	s3,40(sp)
    80004b5e:	ec56                	sd	s5,24(sp)
    80004b60:	e85a                	sd	s6,16(sp)
    80004b62:	0880                	addi	s0,sp,80
    80004b64:	8b2e                	mv	s6,a1
    80004b66:	89b2                	mv	s3,a2
    80004b68:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004b6a:	fb040593          	addi	a1,s0,-80
    80004b6e:	80eff0ef          	jal	80003b7c <nameiparent>
    80004b72:	84aa                	mv	s1,a0
    80004b74:	10050a63          	beqz	a0,80004c88 <create+0x136>
    return 0;

  ilock(dp);
    80004b78:	fd4fe0ef          	jal	8000334c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004b7c:	4601                	li	a2,0
    80004b7e:	fb040593          	addi	a1,s0,-80
    80004b82:	8526                	mv	a0,s1
    80004b84:	d79fe0ef          	jal	800038fc <dirlookup>
    80004b88:	8aaa                	mv	s5,a0
    80004b8a:	c129                	beqz	a0,80004bcc <create+0x7a>
    iunlockput(dp);
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	9c9fe0ef          	jal	80003556 <iunlockput>
    ilock(ip);
    80004b92:	8556                	mv	a0,s5
    80004b94:	fb8fe0ef          	jal	8000334c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004b98:	4789                	li	a5,2
    80004b9a:	02fb1463          	bne	s6,a5,80004bc2 <create+0x70>
    80004b9e:	044ad783          	lhu	a5,68(s5)
    80004ba2:	37f9                	addiw	a5,a5,-2
    80004ba4:	17c2                	slli	a5,a5,0x30
    80004ba6:	93c1                	srli	a5,a5,0x30
    80004ba8:	4705                	li	a4,1
    80004baa:	00f76c63          	bltu	a4,a5,80004bc2 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004bae:	8556                	mv	a0,s5
    80004bb0:	60a6                	ld	ra,72(sp)
    80004bb2:	6406                	ld	s0,64(sp)
    80004bb4:	74e2                	ld	s1,56(sp)
    80004bb6:	7942                	ld	s2,48(sp)
    80004bb8:	79a2                	ld	s3,40(sp)
    80004bba:	6ae2                	ld	s5,24(sp)
    80004bbc:	6b42                	ld	s6,16(sp)
    80004bbe:	6161                	addi	sp,sp,80
    80004bc0:	8082                	ret
    iunlockput(ip);
    80004bc2:	8556                	mv	a0,s5
    80004bc4:	993fe0ef          	jal	80003556 <iunlockput>
    return 0;
    80004bc8:	4a81                	li	s5,0
    80004bca:	b7d5                	j	80004bae <create+0x5c>
    80004bcc:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004bce:	85da                	mv	a1,s6
    80004bd0:	4088                	lw	a0,0(s1)
    80004bd2:	e0afe0ef          	jal	800031dc <ialloc>
    80004bd6:	8a2a                	mv	s4,a0
    80004bd8:	cd15                	beqz	a0,80004c14 <create+0xc2>
  ilock(ip);
    80004bda:	f72fe0ef          	jal	8000334c <ilock>
  ip->major = major;
    80004bde:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004be2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004be6:	4905                	li	s2,1
    80004be8:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004bec:	8552                	mv	a0,s4
    80004bee:	eaafe0ef          	jal	80003298 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004bf2:	032b0763          	beq	s6,s2,80004c20 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004bf6:	004a2603          	lw	a2,4(s4)
    80004bfa:	fb040593          	addi	a1,s0,-80
    80004bfe:	8526                	mv	a0,s1
    80004c00:	ec9fe0ef          	jal	80003ac8 <dirlink>
    80004c04:	06054563          	bltz	a0,80004c6e <create+0x11c>
  iunlockput(dp);
    80004c08:	8526                	mv	a0,s1
    80004c0a:	94dfe0ef          	jal	80003556 <iunlockput>
  return ip;
    80004c0e:	8ad2                	mv	s5,s4
    80004c10:	7a02                	ld	s4,32(sp)
    80004c12:	bf71                	j	80004bae <create+0x5c>
    iunlockput(dp);
    80004c14:	8526                	mv	a0,s1
    80004c16:	941fe0ef          	jal	80003556 <iunlockput>
    return 0;
    80004c1a:	8ad2                	mv	s5,s4
    80004c1c:	7a02                	ld	s4,32(sp)
    80004c1e:	bf41                	j	80004bae <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004c20:	004a2603          	lw	a2,4(s4)
    80004c24:	00003597          	auipc	a1,0x3
    80004c28:	9bc58593          	addi	a1,a1,-1604 # 800075e0 <etext+0x5e0>
    80004c2c:	8552                	mv	a0,s4
    80004c2e:	e9bfe0ef          	jal	80003ac8 <dirlink>
    80004c32:	02054e63          	bltz	a0,80004c6e <create+0x11c>
    80004c36:	40d0                	lw	a2,4(s1)
    80004c38:	00003597          	auipc	a1,0x3
    80004c3c:	9b058593          	addi	a1,a1,-1616 # 800075e8 <etext+0x5e8>
    80004c40:	8552                	mv	a0,s4
    80004c42:	e87fe0ef          	jal	80003ac8 <dirlink>
    80004c46:	02054463          	bltz	a0,80004c6e <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004c4a:	004a2603          	lw	a2,4(s4)
    80004c4e:	fb040593          	addi	a1,s0,-80
    80004c52:	8526                	mv	a0,s1
    80004c54:	e75fe0ef          	jal	80003ac8 <dirlink>
    80004c58:	00054b63          	bltz	a0,80004c6e <create+0x11c>
    dp->nlink++;  // for ".."
    80004c5c:	04a4d783          	lhu	a5,74(s1)
    80004c60:	2785                	addiw	a5,a5,1
    80004c62:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004c66:	8526                	mv	a0,s1
    80004c68:	e30fe0ef          	jal	80003298 <iupdate>
    80004c6c:	bf71                	j	80004c08 <create+0xb6>
  ip->nlink = 0;
    80004c6e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004c72:	8552                	mv	a0,s4
    80004c74:	e24fe0ef          	jal	80003298 <iupdate>
  iunlockput(ip);
    80004c78:	8552                	mv	a0,s4
    80004c7a:	8ddfe0ef          	jal	80003556 <iunlockput>
  iunlockput(dp);
    80004c7e:	8526                	mv	a0,s1
    80004c80:	8d7fe0ef          	jal	80003556 <iunlockput>
  return 0;
    80004c84:	7a02                	ld	s4,32(sp)
    80004c86:	b725                	j	80004bae <create+0x5c>
    return 0;
    80004c88:	8aaa                	mv	s5,a0
    80004c8a:	b715                	j	80004bae <create+0x5c>

0000000080004c8c <sys_dup>:
{
    80004c8c:	7179                	addi	sp,sp,-48
    80004c8e:	f406                	sd	ra,40(sp)
    80004c90:	f022                	sd	s0,32(sp)
    80004c92:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004c94:	fd840613          	addi	a2,s0,-40
    80004c98:	4581                	li	a1,0
    80004c9a:	4501                	li	a0,0
    80004c9c:	e21ff0ef          	jal	80004abc <argfd>
    return -1;
    80004ca0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004ca2:	02054363          	bltz	a0,80004cc8 <sys_dup+0x3c>
    80004ca6:	ec26                	sd	s1,24(sp)
    80004ca8:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004caa:	fd843903          	ld	s2,-40(s0)
    80004cae:	854a                	mv	a0,s2
    80004cb0:	e65ff0ef          	jal	80004b14 <fdalloc>
    80004cb4:	84aa                	mv	s1,a0
    return -1;
    80004cb6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004cb8:	00054d63          	bltz	a0,80004cd2 <sys_dup+0x46>
  filedup(f);
    80004cbc:	854a                	mv	a0,s2
    80004cbe:	c3eff0ef          	jal	800040fc <filedup>
  return fd;
    80004cc2:	87a6                	mv	a5,s1
    80004cc4:	64e2                	ld	s1,24(sp)
    80004cc6:	6942                	ld	s2,16(sp)
}
    80004cc8:	853e                	mv	a0,a5
    80004cca:	70a2                	ld	ra,40(sp)
    80004ccc:	7402                	ld	s0,32(sp)
    80004cce:	6145                	addi	sp,sp,48
    80004cd0:	8082                	ret
    80004cd2:	64e2                	ld	s1,24(sp)
    80004cd4:	6942                	ld	s2,16(sp)
    80004cd6:	bfcd                	j	80004cc8 <sys_dup+0x3c>

0000000080004cd8 <sys_read>:
{
    80004cd8:	7179                	addi	sp,sp,-48
    80004cda:	f406                	sd	ra,40(sp)
    80004cdc:	f022                	sd	s0,32(sp)
    80004cde:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004ce0:	fd840593          	addi	a1,s0,-40
    80004ce4:	4505                	li	a0,1
    80004ce6:	bdbfd0ef          	jal	800028c0 <argaddr>
  argint(2, &n);
    80004cea:	fe440593          	addi	a1,s0,-28
    80004cee:	4509                	li	a0,2
    80004cf0:	bb5fd0ef          	jal	800028a4 <argint>
  if(argfd(0, 0, &f) < 0)
    80004cf4:	fe840613          	addi	a2,s0,-24
    80004cf8:	4581                	li	a1,0
    80004cfa:	4501                	li	a0,0
    80004cfc:	dc1ff0ef          	jal	80004abc <argfd>
    80004d00:	87aa                	mv	a5,a0
    return -1;
    80004d02:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d04:	0007ca63          	bltz	a5,80004d18 <sys_read+0x40>
  return fileread(f, p, n);
    80004d08:	fe442603          	lw	a2,-28(s0)
    80004d0c:	fd843583          	ld	a1,-40(s0)
    80004d10:	fe843503          	ld	a0,-24(s0)
    80004d14:	d4eff0ef          	jal	80004262 <fileread>
}
    80004d18:	70a2                	ld	ra,40(sp)
    80004d1a:	7402                	ld	s0,32(sp)
    80004d1c:	6145                	addi	sp,sp,48
    80004d1e:	8082                	ret

0000000080004d20 <sys_write>:
{
    80004d20:	7179                	addi	sp,sp,-48
    80004d22:	f406                	sd	ra,40(sp)
    80004d24:	f022                	sd	s0,32(sp)
    80004d26:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004d28:	fd840593          	addi	a1,s0,-40
    80004d2c:	4505                	li	a0,1
    80004d2e:	b93fd0ef          	jal	800028c0 <argaddr>
  argint(2, &n);
    80004d32:	fe440593          	addi	a1,s0,-28
    80004d36:	4509                	li	a0,2
    80004d38:	b6dfd0ef          	jal	800028a4 <argint>
  if(argfd(0, 0, &f) < 0)
    80004d3c:	fe840613          	addi	a2,s0,-24
    80004d40:	4581                	li	a1,0
    80004d42:	4501                	li	a0,0
    80004d44:	d79ff0ef          	jal	80004abc <argfd>
    80004d48:	87aa                	mv	a5,a0
    return -1;
    80004d4a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d4c:	0007ca63          	bltz	a5,80004d60 <sys_write+0x40>
  return filewrite(f, p, n);
    80004d50:	fe442603          	lw	a2,-28(s0)
    80004d54:	fd843583          	ld	a1,-40(s0)
    80004d58:	fe843503          	ld	a0,-24(s0)
    80004d5c:	dc4ff0ef          	jal	80004320 <filewrite>
}
    80004d60:	70a2                	ld	ra,40(sp)
    80004d62:	7402                	ld	s0,32(sp)
    80004d64:	6145                	addi	sp,sp,48
    80004d66:	8082                	ret

0000000080004d68 <sys_close>:
{
    80004d68:	1101                	addi	sp,sp,-32
    80004d6a:	ec06                	sd	ra,24(sp)
    80004d6c:	e822                	sd	s0,16(sp)
    80004d6e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004d70:	fe040613          	addi	a2,s0,-32
    80004d74:	fec40593          	addi	a1,s0,-20
    80004d78:	4501                	li	a0,0
    80004d7a:	d43ff0ef          	jal	80004abc <argfd>
    return -1;
    80004d7e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004d80:	02054063          	bltz	a0,80004da0 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004d84:	b4bfc0ef          	jal	800018ce <myproc>
    80004d88:	fec42783          	lw	a5,-20(s0)
    80004d8c:	07e9                	addi	a5,a5,26
    80004d8e:	078e                	slli	a5,a5,0x3
    80004d90:	953e                	add	a0,a0,a5
    80004d92:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004d96:	fe043503          	ld	a0,-32(s0)
    80004d9a:	ba8ff0ef          	jal	80004142 <fileclose>
  return 0;
    80004d9e:	4781                	li	a5,0
}
    80004da0:	853e                	mv	a0,a5
    80004da2:	60e2                	ld	ra,24(sp)
    80004da4:	6442                	ld	s0,16(sp)
    80004da6:	6105                	addi	sp,sp,32
    80004da8:	8082                	ret

0000000080004daa <sys_fstat>:
{
    80004daa:	1101                	addi	sp,sp,-32
    80004dac:	ec06                	sd	ra,24(sp)
    80004dae:	e822                	sd	s0,16(sp)
    80004db0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004db2:	fe040593          	addi	a1,s0,-32
    80004db6:	4505                	li	a0,1
    80004db8:	b09fd0ef          	jal	800028c0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004dbc:	fe840613          	addi	a2,s0,-24
    80004dc0:	4581                	li	a1,0
    80004dc2:	4501                	li	a0,0
    80004dc4:	cf9ff0ef          	jal	80004abc <argfd>
    80004dc8:	87aa                	mv	a5,a0
    return -1;
    80004dca:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004dcc:	0007c863          	bltz	a5,80004ddc <sys_fstat+0x32>
  return filestat(f, st);
    80004dd0:	fe043583          	ld	a1,-32(s0)
    80004dd4:	fe843503          	ld	a0,-24(s0)
    80004dd8:	c2cff0ef          	jal	80004204 <filestat>
}
    80004ddc:	60e2                	ld	ra,24(sp)
    80004dde:	6442                	ld	s0,16(sp)
    80004de0:	6105                	addi	sp,sp,32
    80004de2:	8082                	ret

0000000080004de4 <sys_link>:
{
    80004de4:	7169                	addi	sp,sp,-304
    80004de6:	f606                	sd	ra,296(sp)
    80004de8:	f222                	sd	s0,288(sp)
    80004dea:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004dec:	08000613          	li	a2,128
    80004df0:	ed040593          	addi	a1,s0,-304
    80004df4:	4501                	li	a0,0
    80004df6:	ae7fd0ef          	jal	800028dc <argstr>
    return -1;
    80004dfa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004dfc:	0c054e63          	bltz	a0,80004ed8 <sys_link+0xf4>
    80004e00:	08000613          	li	a2,128
    80004e04:	f5040593          	addi	a1,s0,-176
    80004e08:	4505                	li	a0,1
    80004e0a:	ad3fd0ef          	jal	800028dc <argstr>
    return -1;
    80004e0e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004e10:	0c054463          	bltz	a0,80004ed8 <sys_link+0xf4>
    80004e14:	ee26                	sd	s1,280(sp)
  begin_op();
    80004e16:	f21fe0ef          	jal	80003d36 <begin_op>
  if((ip = namei(old)) == 0){
    80004e1a:	ed040513          	addi	a0,s0,-304
    80004e1e:	d45fe0ef          	jal	80003b62 <namei>
    80004e22:	84aa                	mv	s1,a0
    80004e24:	c53d                	beqz	a0,80004e92 <sys_link+0xae>
  ilock(ip);
    80004e26:	d26fe0ef          	jal	8000334c <ilock>
  if(ip->type == T_DIR){
    80004e2a:	04449703          	lh	a4,68(s1)
    80004e2e:	4785                	li	a5,1
    80004e30:	06f70663          	beq	a4,a5,80004e9c <sys_link+0xb8>
    80004e34:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80004e36:	04a4d783          	lhu	a5,74(s1)
    80004e3a:	2785                	addiw	a5,a5,1
    80004e3c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e40:	8526                	mv	a0,s1
    80004e42:	c56fe0ef          	jal	80003298 <iupdate>
  iunlock(ip);
    80004e46:	8526                	mv	a0,s1
    80004e48:	db2fe0ef          	jal	800033fa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004e4c:	fd040593          	addi	a1,s0,-48
    80004e50:	f5040513          	addi	a0,s0,-176
    80004e54:	d29fe0ef          	jal	80003b7c <nameiparent>
    80004e58:	892a                	mv	s2,a0
    80004e5a:	cd21                	beqz	a0,80004eb2 <sys_link+0xce>
  ilock(dp);
    80004e5c:	cf0fe0ef          	jal	8000334c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004e60:	00092703          	lw	a4,0(s2)
    80004e64:	409c                	lw	a5,0(s1)
    80004e66:	04f71363          	bne	a4,a5,80004eac <sys_link+0xc8>
    80004e6a:	40d0                	lw	a2,4(s1)
    80004e6c:	fd040593          	addi	a1,s0,-48
    80004e70:	854a                	mv	a0,s2
    80004e72:	c57fe0ef          	jal	80003ac8 <dirlink>
    80004e76:	02054b63          	bltz	a0,80004eac <sys_link+0xc8>
  iunlockput(dp);
    80004e7a:	854a                	mv	a0,s2
    80004e7c:	edafe0ef          	jal	80003556 <iunlockput>
  iput(ip);
    80004e80:	8526                	mv	a0,s1
    80004e82:	e4cfe0ef          	jal	800034ce <iput>
  end_op();
    80004e86:	f1bfe0ef          	jal	80003da0 <end_op>
  return 0;
    80004e8a:	4781                	li	a5,0
    80004e8c:	64f2                	ld	s1,280(sp)
    80004e8e:	6952                	ld	s2,272(sp)
    80004e90:	a0a1                	j	80004ed8 <sys_link+0xf4>
    end_op();
    80004e92:	f0ffe0ef          	jal	80003da0 <end_op>
    return -1;
    80004e96:	57fd                	li	a5,-1
    80004e98:	64f2                	ld	s1,280(sp)
    80004e9a:	a83d                	j	80004ed8 <sys_link+0xf4>
    iunlockput(ip);
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	eb8fe0ef          	jal	80003556 <iunlockput>
    end_op();
    80004ea2:	efffe0ef          	jal	80003da0 <end_op>
    return -1;
    80004ea6:	57fd                	li	a5,-1
    80004ea8:	64f2                	ld	s1,280(sp)
    80004eaa:	a03d                	j	80004ed8 <sys_link+0xf4>
    iunlockput(dp);
    80004eac:	854a                	mv	a0,s2
    80004eae:	ea8fe0ef          	jal	80003556 <iunlockput>
  ilock(ip);
    80004eb2:	8526                	mv	a0,s1
    80004eb4:	c98fe0ef          	jal	8000334c <ilock>
  ip->nlink--;
    80004eb8:	04a4d783          	lhu	a5,74(s1)
    80004ebc:	37fd                	addiw	a5,a5,-1
    80004ebe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004ec2:	8526                	mv	a0,s1
    80004ec4:	bd4fe0ef          	jal	80003298 <iupdate>
  iunlockput(ip);
    80004ec8:	8526                	mv	a0,s1
    80004eca:	e8cfe0ef          	jal	80003556 <iunlockput>
  end_op();
    80004ece:	ed3fe0ef          	jal	80003da0 <end_op>
  return -1;
    80004ed2:	57fd                	li	a5,-1
    80004ed4:	64f2                	ld	s1,280(sp)
    80004ed6:	6952                	ld	s2,272(sp)
}
    80004ed8:	853e                	mv	a0,a5
    80004eda:	70b2                	ld	ra,296(sp)
    80004edc:	7412                	ld	s0,288(sp)
    80004ede:	6155                	addi	sp,sp,304
    80004ee0:	8082                	ret

0000000080004ee2 <sys_unlink>:
{
    80004ee2:	7151                	addi	sp,sp,-240
    80004ee4:	f586                	sd	ra,232(sp)
    80004ee6:	f1a2                	sd	s0,224(sp)
    80004ee8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80004eea:	08000613          	li	a2,128
    80004eee:	f3040593          	addi	a1,s0,-208
    80004ef2:	4501                	li	a0,0
    80004ef4:	9e9fd0ef          	jal	800028dc <argstr>
    80004ef8:	16054063          	bltz	a0,80005058 <sys_unlink+0x176>
    80004efc:	eda6                	sd	s1,216(sp)
  begin_op();
    80004efe:	e39fe0ef          	jal	80003d36 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004f02:	fb040593          	addi	a1,s0,-80
    80004f06:	f3040513          	addi	a0,s0,-208
    80004f0a:	c73fe0ef          	jal	80003b7c <nameiparent>
    80004f0e:	84aa                	mv	s1,a0
    80004f10:	c945                	beqz	a0,80004fc0 <sys_unlink+0xde>
  ilock(dp);
    80004f12:	c3afe0ef          	jal	8000334c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004f16:	00002597          	auipc	a1,0x2
    80004f1a:	6ca58593          	addi	a1,a1,1738 # 800075e0 <etext+0x5e0>
    80004f1e:	fb040513          	addi	a0,s0,-80
    80004f22:	9c5fe0ef          	jal	800038e6 <namecmp>
    80004f26:	10050e63          	beqz	a0,80005042 <sys_unlink+0x160>
    80004f2a:	00002597          	auipc	a1,0x2
    80004f2e:	6be58593          	addi	a1,a1,1726 # 800075e8 <etext+0x5e8>
    80004f32:	fb040513          	addi	a0,s0,-80
    80004f36:	9b1fe0ef          	jal	800038e6 <namecmp>
    80004f3a:	10050463          	beqz	a0,80005042 <sys_unlink+0x160>
    80004f3e:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004f40:	f2c40613          	addi	a2,s0,-212
    80004f44:	fb040593          	addi	a1,s0,-80
    80004f48:	8526                	mv	a0,s1
    80004f4a:	9b3fe0ef          	jal	800038fc <dirlookup>
    80004f4e:	892a                	mv	s2,a0
    80004f50:	0e050863          	beqz	a0,80005040 <sys_unlink+0x15e>
  ilock(ip);
    80004f54:	bf8fe0ef          	jal	8000334c <ilock>
  if(ip->nlink < 1)
    80004f58:	04a91783          	lh	a5,74(s2)
    80004f5c:	06f05763          	blez	a5,80004fca <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004f60:	04491703          	lh	a4,68(s2)
    80004f64:	4785                	li	a5,1
    80004f66:	06f70963          	beq	a4,a5,80004fd8 <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    80004f6a:	4641                	li	a2,16
    80004f6c:	4581                	li	a1,0
    80004f6e:	fc040513          	addi	a0,s0,-64
    80004f72:	d31fb0ef          	jal	80000ca2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004f76:	4741                	li	a4,16
    80004f78:	f2c42683          	lw	a3,-212(s0)
    80004f7c:	fc040613          	addi	a2,s0,-64
    80004f80:	4581                	li	a1,0
    80004f82:	8526                	mv	a0,s1
    80004f84:	855fe0ef          	jal	800037d8 <writei>
    80004f88:	47c1                	li	a5,16
    80004f8a:	08f51b63          	bne	a0,a5,80005020 <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    80004f8e:	04491703          	lh	a4,68(s2)
    80004f92:	4785                	li	a5,1
    80004f94:	08f70d63          	beq	a4,a5,8000502e <sys_unlink+0x14c>
  iunlockput(dp);
    80004f98:	8526                	mv	a0,s1
    80004f9a:	dbcfe0ef          	jal	80003556 <iunlockput>
  ip->nlink--;
    80004f9e:	04a95783          	lhu	a5,74(s2)
    80004fa2:	37fd                	addiw	a5,a5,-1
    80004fa4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004fa8:	854a                	mv	a0,s2
    80004faa:	aeefe0ef          	jal	80003298 <iupdate>
  iunlockput(ip);
    80004fae:	854a                	mv	a0,s2
    80004fb0:	da6fe0ef          	jal	80003556 <iunlockput>
  end_op();
    80004fb4:	dedfe0ef          	jal	80003da0 <end_op>
  return 0;
    80004fb8:	4501                	li	a0,0
    80004fba:	64ee                	ld	s1,216(sp)
    80004fbc:	694e                	ld	s2,208(sp)
    80004fbe:	a849                	j	80005050 <sys_unlink+0x16e>
    end_op();
    80004fc0:	de1fe0ef          	jal	80003da0 <end_op>
    return -1;
    80004fc4:	557d                	li	a0,-1
    80004fc6:	64ee                	ld	s1,216(sp)
    80004fc8:	a061                	j	80005050 <sys_unlink+0x16e>
    80004fca:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80004fcc:	00002517          	auipc	a0,0x2
    80004fd0:	62450513          	addi	a0,a0,1572 # 800075f0 <etext+0x5f0>
    80004fd4:	80dfb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004fd8:	04c92703          	lw	a4,76(s2)
    80004fdc:	02000793          	li	a5,32
    80004fe0:	f8e7f5e3          	bgeu	a5,a4,80004f6a <sys_unlink+0x88>
    80004fe4:	e5ce                	sd	s3,200(sp)
    80004fe6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004fea:	4741                	li	a4,16
    80004fec:	86ce                	mv	a3,s3
    80004fee:	f1840613          	addi	a2,s0,-232
    80004ff2:	4581                	li	a1,0
    80004ff4:	854a                	mv	a0,s2
    80004ff6:	ee6fe0ef          	jal	800036dc <readi>
    80004ffa:	47c1                	li	a5,16
    80004ffc:	00f51c63          	bne	a0,a5,80005014 <sys_unlink+0x132>
    if(de.inum != 0)
    80005000:	f1845783          	lhu	a5,-232(s0)
    80005004:	efa1                	bnez	a5,8000505c <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005006:	29c1                	addiw	s3,s3,16
    80005008:	04c92783          	lw	a5,76(s2)
    8000500c:	fcf9efe3          	bltu	s3,a5,80004fea <sys_unlink+0x108>
    80005010:	69ae                	ld	s3,200(sp)
    80005012:	bfa1                	j	80004f6a <sys_unlink+0x88>
      panic("isdirempty: readi");
    80005014:	00002517          	auipc	a0,0x2
    80005018:	5f450513          	addi	a0,a0,1524 # 80007608 <etext+0x608>
    8000501c:	fc4fb0ef          	jal	800007e0 <panic>
    80005020:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005022:	00002517          	auipc	a0,0x2
    80005026:	5fe50513          	addi	a0,a0,1534 # 80007620 <etext+0x620>
    8000502a:	fb6fb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    8000502e:	04a4d783          	lhu	a5,74(s1)
    80005032:	37fd                	addiw	a5,a5,-1
    80005034:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005038:	8526                	mv	a0,s1
    8000503a:	a5efe0ef          	jal	80003298 <iupdate>
    8000503e:	bfa9                	j	80004f98 <sys_unlink+0xb6>
    80005040:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    80005042:	8526                	mv	a0,s1
    80005044:	d12fe0ef          	jal	80003556 <iunlockput>
  end_op();
    80005048:	d59fe0ef          	jal	80003da0 <end_op>
  return -1;
    8000504c:	557d                	li	a0,-1
    8000504e:	64ee                	ld	s1,216(sp)
}
    80005050:	70ae                	ld	ra,232(sp)
    80005052:	740e                	ld	s0,224(sp)
    80005054:	616d                	addi	sp,sp,240
    80005056:	8082                	ret
    return -1;
    80005058:	557d                	li	a0,-1
    8000505a:	bfdd                	j	80005050 <sys_unlink+0x16e>
    iunlockput(ip);
    8000505c:	854a                	mv	a0,s2
    8000505e:	cf8fe0ef          	jal	80003556 <iunlockput>
    goto bad;
    80005062:	694e                	ld	s2,208(sp)
    80005064:	69ae                	ld	s3,200(sp)
    80005066:	bff1                	j	80005042 <sys_unlink+0x160>

0000000080005068 <sys_open>:

uint64
sys_open(void)
{
    80005068:	7131                	addi	sp,sp,-192
    8000506a:	fd06                	sd	ra,184(sp)
    8000506c:	f922                	sd	s0,176(sp)
    8000506e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005070:	f4c40593          	addi	a1,s0,-180
    80005074:	4505                	li	a0,1
    80005076:	82ffd0ef          	jal	800028a4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000507a:	08000613          	li	a2,128
    8000507e:	f5040593          	addi	a1,s0,-176
    80005082:	4501                	li	a0,0
    80005084:	859fd0ef          	jal	800028dc <argstr>
    80005088:	87aa                	mv	a5,a0
    return -1;
    8000508a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000508c:	0a07c263          	bltz	a5,80005130 <sys_open+0xc8>
    80005090:	f526                	sd	s1,168(sp)

  begin_op();
    80005092:	ca5fe0ef          	jal	80003d36 <begin_op>

  if(omode & O_CREATE){
    80005096:	f4c42783          	lw	a5,-180(s0)
    8000509a:	2007f793          	andi	a5,a5,512
    8000509e:	c3d5                	beqz	a5,80005142 <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    800050a0:	4681                	li	a3,0
    800050a2:	4601                	li	a2,0
    800050a4:	4589                	li	a1,2
    800050a6:	f5040513          	addi	a0,s0,-176
    800050aa:	aa9ff0ef          	jal	80004b52 <create>
    800050ae:	84aa                	mv	s1,a0
    if(ip == 0){
    800050b0:	c541                	beqz	a0,80005138 <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800050b2:	04449703          	lh	a4,68(s1)
    800050b6:	478d                	li	a5,3
    800050b8:	00f71763          	bne	a4,a5,800050c6 <sys_open+0x5e>
    800050bc:	0464d703          	lhu	a4,70(s1)
    800050c0:	47a5                	li	a5,9
    800050c2:	0ae7ed63          	bltu	a5,a4,8000517c <sys_open+0x114>
    800050c6:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800050c8:	fd7fe0ef          	jal	8000409e <filealloc>
    800050cc:	892a                	mv	s2,a0
    800050ce:	c179                	beqz	a0,80005194 <sys_open+0x12c>
    800050d0:	ed4e                	sd	s3,152(sp)
    800050d2:	a43ff0ef          	jal	80004b14 <fdalloc>
    800050d6:	89aa                	mv	s3,a0
    800050d8:	0a054a63          	bltz	a0,8000518c <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800050dc:	04449703          	lh	a4,68(s1)
    800050e0:	478d                	li	a5,3
    800050e2:	0cf70263          	beq	a4,a5,800051a6 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800050e6:	4789                	li	a5,2
    800050e8:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800050ec:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800050f0:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800050f4:	f4c42783          	lw	a5,-180(s0)
    800050f8:	0017c713          	xori	a4,a5,1
    800050fc:	8b05                	andi	a4,a4,1
    800050fe:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005102:	0037f713          	andi	a4,a5,3
    80005106:	00e03733          	snez	a4,a4
    8000510a:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000510e:	4007f793          	andi	a5,a5,1024
    80005112:	c791                	beqz	a5,8000511e <sys_open+0xb6>
    80005114:	04449703          	lh	a4,68(s1)
    80005118:	4789                	li	a5,2
    8000511a:	08f70d63          	beq	a4,a5,800051b4 <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    8000511e:	8526                	mv	a0,s1
    80005120:	adafe0ef          	jal	800033fa <iunlock>
  end_op();
    80005124:	c7dfe0ef          	jal	80003da0 <end_op>

  return fd;
    80005128:	854e                	mv	a0,s3
    8000512a:	74aa                	ld	s1,168(sp)
    8000512c:	790a                	ld	s2,160(sp)
    8000512e:	69ea                	ld	s3,152(sp)
}
    80005130:	70ea                	ld	ra,184(sp)
    80005132:	744a                	ld	s0,176(sp)
    80005134:	6129                	addi	sp,sp,192
    80005136:	8082                	ret
      end_op();
    80005138:	c69fe0ef          	jal	80003da0 <end_op>
      return -1;
    8000513c:	557d                	li	a0,-1
    8000513e:	74aa                	ld	s1,168(sp)
    80005140:	bfc5                	j	80005130 <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    80005142:	f5040513          	addi	a0,s0,-176
    80005146:	a1dfe0ef          	jal	80003b62 <namei>
    8000514a:	84aa                	mv	s1,a0
    8000514c:	c11d                	beqz	a0,80005172 <sys_open+0x10a>
    ilock(ip);
    8000514e:	9fefe0ef          	jal	8000334c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005152:	04449703          	lh	a4,68(s1)
    80005156:	4785                	li	a5,1
    80005158:	f4f71de3          	bne	a4,a5,800050b2 <sys_open+0x4a>
    8000515c:	f4c42783          	lw	a5,-180(s0)
    80005160:	d3bd                	beqz	a5,800050c6 <sys_open+0x5e>
      iunlockput(ip);
    80005162:	8526                	mv	a0,s1
    80005164:	bf2fe0ef          	jal	80003556 <iunlockput>
      end_op();
    80005168:	c39fe0ef          	jal	80003da0 <end_op>
      return -1;
    8000516c:	557d                	li	a0,-1
    8000516e:	74aa                	ld	s1,168(sp)
    80005170:	b7c1                	j	80005130 <sys_open+0xc8>
      end_op();
    80005172:	c2ffe0ef          	jal	80003da0 <end_op>
      return -1;
    80005176:	557d                	li	a0,-1
    80005178:	74aa                	ld	s1,168(sp)
    8000517a:	bf5d                	j	80005130 <sys_open+0xc8>
    iunlockput(ip);
    8000517c:	8526                	mv	a0,s1
    8000517e:	bd8fe0ef          	jal	80003556 <iunlockput>
    end_op();
    80005182:	c1ffe0ef          	jal	80003da0 <end_op>
    return -1;
    80005186:	557d                	li	a0,-1
    80005188:	74aa                	ld	s1,168(sp)
    8000518a:	b75d                	j	80005130 <sys_open+0xc8>
      fileclose(f);
    8000518c:	854a                	mv	a0,s2
    8000518e:	fb5fe0ef          	jal	80004142 <fileclose>
    80005192:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    80005194:	8526                	mv	a0,s1
    80005196:	bc0fe0ef          	jal	80003556 <iunlockput>
    end_op();
    8000519a:	c07fe0ef          	jal	80003da0 <end_op>
    return -1;
    8000519e:	557d                	li	a0,-1
    800051a0:	74aa                	ld	s1,168(sp)
    800051a2:	790a                	ld	s2,160(sp)
    800051a4:	b771                	j	80005130 <sys_open+0xc8>
    f->type = FD_DEVICE;
    800051a6:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800051aa:	04649783          	lh	a5,70(s1)
    800051ae:	02f91223          	sh	a5,36(s2)
    800051b2:	bf3d                	j	800050f0 <sys_open+0x88>
    itrunc(ip);
    800051b4:	8526                	mv	a0,s1
    800051b6:	a84fe0ef          	jal	8000343a <itrunc>
    800051ba:	b795                	j	8000511e <sys_open+0xb6>

00000000800051bc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800051bc:	7175                	addi	sp,sp,-144
    800051be:	e506                	sd	ra,136(sp)
    800051c0:	e122                	sd	s0,128(sp)
    800051c2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800051c4:	b73fe0ef          	jal	80003d36 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800051c8:	08000613          	li	a2,128
    800051cc:	f7040593          	addi	a1,s0,-144
    800051d0:	4501                	li	a0,0
    800051d2:	f0afd0ef          	jal	800028dc <argstr>
    800051d6:	02054363          	bltz	a0,800051fc <sys_mkdir+0x40>
    800051da:	4681                	li	a3,0
    800051dc:	4601                	li	a2,0
    800051de:	4585                	li	a1,1
    800051e0:	f7040513          	addi	a0,s0,-144
    800051e4:	96fff0ef          	jal	80004b52 <create>
    800051e8:	c911                	beqz	a0,800051fc <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800051ea:	b6cfe0ef          	jal	80003556 <iunlockput>
  end_op();
    800051ee:	bb3fe0ef          	jal	80003da0 <end_op>
  return 0;
    800051f2:	4501                	li	a0,0
}
    800051f4:	60aa                	ld	ra,136(sp)
    800051f6:	640a                	ld	s0,128(sp)
    800051f8:	6149                	addi	sp,sp,144
    800051fa:	8082                	ret
    end_op();
    800051fc:	ba5fe0ef          	jal	80003da0 <end_op>
    return -1;
    80005200:	557d                	li	a0,-1
    80005202:	bfcd                	j	800051f4 <sys_mkdir+0x38>

0000000080005204 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005204:	7135                	addi	sp,sp,-160
    80005206:	ed06                	sd	ra,152(sp)
    80005208:	e922                	sd	s0,144(sp)
    8000520a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000520c:	b2bfe0ef          	jal	80003d36 <begin_op>
  argint(1, &major);
    80005210:	f6c40593          	addi	a1,s0,-148
    80005214:	4505                	li	a0,1
    80005216:	e8efd0ef          	jal	800028a4 <argint>
  argint(2, &minor);
    8000521a:	f6840593          	addi	a1,s0,-152
    8000521e:	4509                	li	a0,2
    80005220:	e84fd0ef          	jal	800028a4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005224:	08000613          	li	a2,128
    80005228:	f7040593          	addi	a1,s0,-144
    8000522c:	4501                	li	a0,0
    8000522e:	eaefd0ef          	jal	800028dc <argstr>
    80005232:	02054563          	bltz	a0,8000525c <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005236:	f6841683          	lh	a3,-152(s0)
    8000523a:	f6c41603          	lh	a2,-148(s0)
    8000523e:	458d                	li	a1,3
    80005240:	f7040513          	addi	a0,s0,-144
    80005244:	90fff0ef          	jal	80004b52 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005248:	c911                	beqz	a0,8000525c <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000524a:	b0cfe0ef          	jal	80003556 <iunlockput>
  end_op();
    8000524e:	b53fe0ef          	jal	80003da0 <end_op>
  return 0;
    80005252:	4501                	li	a0,0
}
    80005254:	60ea                	ld	ra,152(sp)
    80005256:	644a                	ld	s0,144(sp)
    80005258:	610d                	addi	sp,sp,160
    8000525a:	8082                	ret
    end_op();
    8000525c:	b45fe0ef          	jal	80003da0 <end_op>
    return -1;
    80005260:	557d                	li	a0,-1
    80005262:	bfcd                	j	80005254 <sys_mknod+0x50>

0000000080005264 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005264:	7135                	addi	sp,sp,-160
    80005266:	ed06                	sd	ra,152(sp)
    80005268:	e922                	sd	s0,144(sp)
    8000526a:	e14a                	sd	s2,128(sp)
    8000526c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000526e:	e60fc0ef          	jal	800018ce <myproc>
    80005272:	892a                	mv	s2,a0
  
  begin_op();
    80005274:	ac3fe0ef          	jal	80003d36 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005278:	08000613          	li	a2,128
    8000527c:	f6040593          	addi	a1,s0,-160
    80005280:	4501                	li	a0,0
    80005282:	e5afd0ef          	jal	800028dc <argstr>
    80005286:	04054363          	bltz	a0,800052cc <sys_chdir+0x68>
    8000528a:	e526                	sd	s1,136(sp)
    8000528c:	f6040513          	addi	a0,s0,-160
    80005290:	8d3fe0ef          	jal	80003b62 <namei>
    80005294:	84aa                	mv	s1,a0
    80005296:	c915                	beqz	a0,800052ca <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    80005298:	8b4fe0ef          	jal	8000334c <ilock>
  if(ip->type != T_DIR){
    8000529c:	04449703          	lh	a4,68(s1)
    800052a0:	4785                	li	a5,1
    800052a2:	02f71963          	bne	a4,a5,800052d4 <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800052a6:	8526                	mv	a0,s1
    800052a8:	952fe0ef          	jal	800033fa <iunlock>
  iput(p->cwd);
    800052ac:	15093503          	ld	a0,336(s2)
    800052b0:	a1efe0ef          	jal	800034ce <iput>
  end_op();
    800052b4:	aedfe0ef          	jal	80003da0 <end_op>
  p->cwd = ip;
    800052b8:	14993823          	sd	s1,336(s2)
  return 0;
    800052bc:	4501                	li	a0,0
    800052be:	64aa                	ld	s1,136(sp)
}
    800052c0:	60ea                	ld	ra,152(sp)
    800052c2:	644a                	ld	s0,144(sp)
    800052c4:	690a                	ld	s2,128(sp)
    800052c6:	610d                	addi	sp,sp,160
    800052c8:	8082                	ret
    800052ca:	64aa                	ld	s1,136(sp)
    end_op();
    800052cc:	ad5fe0ef          	jal	80003da0 <end_op>
    return -1;
    800052d0:	557d                	li	a0,-1
    800052d2:	b7fd                	j	800052c0 <sys_chdir+0x5c>
    iunlockput(ip);
    800052d4:	8526                	mv	a0,s1
    800052d6:	a80fe0ef          	jal	80003556 <iunlockput>
    end_op();
    800052da:	ac7fe0ef          	jal	80003da0 <end_op>
    return -1;
    800052de:	557d                	li	a0,-1
    800052e0:	64aa                	ld	s1,136(sp)
    800052e2:	bff9                	j	800052c0 <sys_chdir+0x5c>

00000000800052e4 <sys_exec>:

uint64
sys_exec(void)
{
    800052e4:	7121                	addi	sp,sp,-448
    800052e6:	ff06                	sd	ra,440(sp)
    800052e8:	fb22                	sd	s0,432(sp)
    800052ea:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800052ec:	e4840593          	addi	a1,s0,-440
    800052f0:	4505                	li	a0,1
    800052f2:	dcefd0ef          	jal	800028c0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800052f6:	08000613          	li	a2,128
    800052fa:	f5040593          	addi	a1,s0,-176
    800052fe:	4501                	li	a0,0
    80005300:	ddcfd0ef          	jal	800028dc <argstr>
    80005304:	87aa                	mv	a5,a0
    return -1;
    80005306:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005308:	0c07c463          	bltz	a5,800053d0 <sys_exec+0xec>
    8000530c:	f726                	sd	s1,424(sp)
    8000530e:	f34a                	sd	s2,416(sp)
    80005310:	ef4e                	sd	s3,408(sp)
    80005312:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    80005314:	10000613          	li	a2,256
    80005318:	4581                	li	a1,0
    8000531a:	e5040513          	addi	a0,s0,-432
    8000531e:	985fb0ef          	jal	80000ca2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005322:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005326:	89a6                	mv	s3,s1
    80005328:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000532a:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000532e:	00391513          	slli	a0,s2,0x3
    80005332:	e4040593          	addi	a1,s0,-448
    80005336:	e4843783          	ld	a5,-440(s0)
    8000533a:	953e                	add	a0,a0,a5
    8000533c:	cdefd0ef          	jal	8000281a <fetchaddr>
    80005340:	02054663          	bltz	a0,8000536c <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    80005344:	e4043783          	ld	a5,-448(s0)
    80005348:	c3a9                	beqz	a5,8000538a <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000534a:	fb4fb0ef          	jal	80000afe <kalloc>
    8000534e:	85aa                	mv	a1,a0
    80005350:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005354:	cd01                	beqz	a0,8000536c <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005356:	6605                	lui	a2,0x1
    80005358:	e4043503          	ld	a0,-448(s0)
    8000535c:	d08fd0ef          	jal	80002864 <fetchstr>
    80005360:	00054663          	bltz	a0,8000536c <sys_exec+0x88>
    if(i >= NELEM(argv)){
    80005364:	0905                	addi	s2,s2,1
    80005366:	09a1                	addi	s3,s3,8
    80005368:	fd4913e3          	bne	s2,s4,8000532e <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000536c:	f5040913          	addi	s2,s0,-176
    80005370:	6088                	ld	a0,0(s1)
    80005372:	c931                	beqz	a0,800053c6 <sys_exec+0xe2>
    kfree(argv[i]);
    80005374:	ea8fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005378:	04a1                	addi	s1,s1,8
    8000537a:	ff249be3          	bne	s1,s2,80005370 <sys_exec+0x8c>
  return -1;
    8000537e:	557d                	li	a0,-1
    80005380:	74ba                	ld	s1,424(sp)
    80005382:	791a                	ld	s2,416(sp)
    80005384:	69fa                	ld	s3,408(sp)
    80005386:	6a5a                	ld	s4,400(sp)
    80005388:	a0a1                	j	800053d0 <sys_exec+0xec>
      argv[i] = 0;
    8000538a:	0009079b          	sext.w	a5,s2
    8000538e:	078e                	slli	a5,a5,0x3
    80005390:	fd078793          	addi	a5,a5,-48
    80005394:	97a2                	add	a5,a5,s0
    80005396:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    8000539a:	e5040593          	addi	a1,s0,-432
    8000539e:	f5040513          	addi	a0,s0,-176
    800053a2:	ba8ff0ef          	jal	8000474a <kexec>
    800053a6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800053a8:	f5040993          	addi	s3,s0,-176
    800053ac:	6088                	ld	a0,0(s1)
    800053ae:	c511                	beqz	a0,800053ba <sys_exec+0xd6>
    kfree(argv[i]);
    800053b0:	e6cfb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800053b4:	04a1                	addi	s1,s1,8
    800053b6:	ff349be3          	bne	s1,s3,800053ac <sys_exec+0xc8>
  return ret;
    800053ba:	854a                	mv	a0,s2
    800053bc:	74ba                	ld	s1,424(sp)
    800053be:	791a                	ld	s2,416(sp)
    800053c0:	69fa                	ld	s3,408(sp)
    800053c2:	6a5a                	ld	s4,400(sp)
    800053c4:	a031                	j	800053d0 <sys_exec+0xec>
  return -1;
    800053c6:	557d                	li	a0,-1
    800053c8:	74ba                	ld	s1,424(sp)
    800053ca:	791a                	ld	s2,416(sp)
    800053cc:	69fa                	ld	s3,408(sp)
    800053ce:	6a5a                	ld	s4,400(sp)
}
    800053d0:	70fa                	ld	ra,440(sp)
    800053d2:	745a                	ld	s0,432(sp)
    800053d4:	6139                	addi	sp,sp,448
    800053d6:	8082                	ret

00000000800053d8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800053d8:	7139                	addi	sp,sp,-64
    800053da:	fc06                	sd	ra,56(sp)
    800053dc:	f822                	sd	s0,48(sp)
    800053de:	f426                	sd	s1,40(sp)
    800053e0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800053e2:	cecfc0ef          	jal	800018ce <myproc>
    800053e6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800053e8:	fd840593          	addi	a1,s0,-40
    800053ec:	4501                	li	a0,0
    800053ee:	cd2fd0ef          	jal	800028c0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800053f2:	fc840593          	addi	a1,s0,-56
    800053f6:	fd040513          	addi	a0,s0,-48
    800053fa:	852ff0ef          	jal	8000444c <pipealloc>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005400:	0a054463          	bltz	a0,800054a8 <sys_pipe+0xd0>
  fd0 = -1;
    80005404:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005408:	fd043503          	ld	a0,-48(s0)
    8000540c:	f08ff0ef          	jal	80004b14 <fdalloc>
    80005410:	fca42223          	sw	a0,-60(s0)
    80005414:	08054163          	bltz	a0,80005496 <sys_pipe+0xbe>
    80005418:	fc843503          	ld	a0,-56(s0)
    8000541c:	ef8ff0ef          	jal	80004b14 <fdalloc>
    80005420:	fca42023          	sw	a0,-64(s0)
    80005424:	06054063          	bltz	a0,80005484 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005428:	4691                	li	a3,4
    8000542a:	fc440613          	addi	a2,s0,-60
    8000542e:	fd843583          	ld	a1,-40(s0)
    80005432:	68a8                	ld	a0,80(s1)
    80005434:	9aefc0ef          	jal	800015e2 <copyout>
    80005438:	00054e63          	bltz	a0,80005454 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000543c:	4691                	li	a3,4
    8000543e:	fc040613          	addi	a2,s0,-64
    80005442:	fd843583          	ld	a1,-40(s0)
    80005446:	0591                	addi	a1,a1,4
    80005448:	68a8                	ld	a0,80(s1)
    8000544a:	998fc0ef          	jal	800015e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000544e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005450:	04055c63          	bgez	a0,800054a8 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    80005454:	fc442783          	lw	a5,-60(s0)
    80005458:	07e9                	addi	a5,a5,26
    8000545a:	078e                	slli	a5,a5,0x3
    8000545c:	97a6                	add	a5,a5,s1
    8000545e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005462:	fc042783          	lw	a5,-64(s0)
    80005466:	07e9                	addi	a5,a5,26
    80005468:	078e                	slli	a5,a5,0x3
    8000546a:	94be                	add	s1,s1,a5
    8000546c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005470:	fd043503          	ld	a0,-48(s0)
    80005474:	ccffe0ef          	jal	80004142 <fileclose>
    fileclose(wf);
    80005478:	fc843503          	ld	a0,-56(s0)
    8000547c:	cc7fe0ef          	jal	80004142 <fileclose>
    return -1;
    80005480:	57fd                	li	a5,-1
    80005482:	a01d                	j	800054a8 <sys_pipe+0xd0>
    if(fd0 >= 0)
    80005484:	fc442783          	lw	a5,-60(s0)
    80005488:	0007c763          	bltz	a5,80005496 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    8000548c:	07e9                	addi	a5,a5,26
    8000548e:	078e                	slli	a5,a5,0x3
    80005490:	97a6                	add	a5,a5,s1
    80005492:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005496:	fd043503          	ld	a0,-48(s0)
    8000549a:	ca9fe0ef          	jal	80004142 <fileclose>
    fileclose(wf);
    8000549e:	fc843503          	ld	a0,-56(s0)
    800054a2:	ca1fe0ef          	jal	80004142 <fileclose>
    return -1;
    800054a6:	57fd                	li	a5,-1
}
    800054a8:	853e                	mv	a0,a5
    800054aa:	70e2                	ld	ra,56(sp)
    800054ac:	7442                	ld	s0,48(sp)
    800054ae:	74a2                	ld	s1,40(sp)
    800054b0:	6121                	addi	sp,sp,64
    800054b2:	8082                	ret
	...

00000000800054c0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800054c0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800054c2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800054c4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800054c6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800054c8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800054ca:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800054cc:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800054ce:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800054d0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800054d2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800054d4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800054d6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800054d8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800054da:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800054dc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800054de:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800054e0:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800054e2:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800054e4:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    800054e6:	a44fd0ef          	jal	8000272a <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    800054ea:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    800054ec:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    800054ee:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800054f0:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800054f2:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    800054f4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800054f6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800054f8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800054fa:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800054fc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800054fe:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005500:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005502:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005504:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005506:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005508:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000550a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000550c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000550e:	10200073          	sret
	...

000000008000551e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000551e:	1141                	addi	sp,sp,-16
    80005520:	e422                	sd	s0,8(sp)
    80005522:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005524:	0c0007b7          	lui	a5,0xc000
    80005528:	4705                	li	a4,1
    8000552a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000552c:	0c0007b7          	lui	a5,0xc000
    80005530:	c3d8                	sw	a4,4(a5)
}
    80005532:	6422                	ld	s0,8(sp)
    80005534:	0141                	addi	sp,sp,16
    80005536:	8082                	ret

0000000080005538 <plicinithart>:

void
plicinithart(void)
{
    80005538:	1141                	addi	sp,sp,-16
    8000553a:	e406                	sd	ra,8(sp)
    8000553c:	e022                	sd	s0,0(sp)
    8000553e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005540:	b62fc0ef          	jal	800018a2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005544:	0085171b          	slliw	a4,a0,0x8
    80005548:	0c0027b7          	lui	a5,0xc002
    8000554c:	97ba                	add	a5,a5,a4
    8000554e:	40200713          	li	a4,1026
    80005552:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005556:	00d5151b          	slliw	a0,a0,0xd
    8000555a:	0c2017b7          	lui	a5,0xc201
    8000555e:	97aa                	add	a5,a5,a0
    80005560:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005564:	60a2                	ld	ra,8(sp)
    80005566:	6402                	ld	s0,0(sp)
    80005568:	0141                	addi	sp,sp,16
    8000556a:	8082                	ret

000000008000556c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000556c:	1141                	addi	sp,sp,-16
    8000556e:	e406                	sd	ra,8(sp)
    80005570:	e022                	sd	s0,0(sp)
    80005572:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005574:	b2efc0ef          	jal	800018a2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005578:	00d5151b          	slliw	a0,a0,0xd
    8000557c:	0c2017b7          	lui	a5,0xc201
    80005580:	97aa                	add	a5,a5,a0
  return irq;
}
    80005582:	43c8                	lw	a0,4(a5)
    80005584:	60a2                	ld	ra,8(sp)
    80005586:	6402                	ld	s0,0(sp)
    80005588:	0141                	addi	sp,sp,16
    8000558a:	8082                	ret

000000008000558c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000558c:	1101                	addi	sp,sp,-32
    8000558e:	ec06                	sd	ra,24(sp)
    80005590:	e822                	sd	s0,16(sp)
    80005592:	e426                	sd	s1,8(sp)
    80005594:	1000                	addi	s0,sp,32
    80005596:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005598:	b0afc0ef          	jal	800018a2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000559c:	00d5151b          	slliw	a0,a0,0xd
    800055a0:	0c2017b7          	lui	a5,0xc201
    800055a4:	97aa                	add	a5,a5,a0
    800055a6:	c3c4                	sw	s1,4(a5)
}
    800055a8:	60e2                	ld	ra,24(sp)
    800055aa:	6442                	ld	s0,16(sp)
    800055ac:	64a2                	ld	s1,8(sp)
    800055ae:	6105                	addi	sp,sp,32
    800055b0:	8082                	ret

00000000800055b2 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800055b2:	1141                	addi	sp,sp,-16
    800055b4:	e406                	sd	ra,8(sp)
    800055b6:	e022                	sd	s0,0(sp)
    800055b8:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800055ba:	479d                	li	a5,7
    800055bc:	04a7ca63          	blt	a5,a0,80005610 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    800055c0:	0001e797          	auipc	a5,0x1e
    800055c4:	08878793          	addi	a5,a5,136 # 80023648 <disk>
    800055c8:	97aa                	add	a5,a5,a0
    800055ca:	0187c783          	lbu	a5,24(a5)
    800055ce:	e7b9                	bnez	a5,8000561c <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800055d0:	00451693          	slli	a3,a0,0x4
    800055d4:	0001e797          	auipc	a5,0x1e
    800055d8:	07478793          	addi	a5,a5,116 # 80023648 <disk>
    800055dc:	6398                	ld	a4,0(a5)
    800055de:	9736                	add	a4,a4,a3
    800055e0:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800055e4:	6398                	ld	a4,0(a5)
    800055e6:	9736                	add	a4,a4,a3
    800055e8:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800055ec:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800055f0:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800055f4:	97aa                	add	a5,a5,a0
    800055f6:	4705                	li	a4,1
    800055f8:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800055fc:	0001e517          	auipc	a0,0x1e
    80005600:	06450513          	addi	a0,a0,100 # 80023660 <disk+0x18>
    80005604:	983fc0ef          	jal	80001f86 <wakeup>
}
    80005608:	60a2                	ld	ra,8(sp)
    8000560a:	6402                	ld	s0,0(sp)
    8000560c:	0141                	addi	sp,sp,16
    8000560e:	8082                	ret
    panic("free_desc 1");
    80005610:	00002517          	auipc	a0,0x2
    80005614:	02050513          	addi	a0,a0,32 # 80007630 <etext+0x630>
    80005618:	9c8fb0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    8000561c:	00002517          	auipc	a0,0x2
    80005620:	02450513          	addi	a0,a0,36 # 80007640 <etext+0x640>
    80005624:	9bcfb0ef          	jal	800007e0 <panic>

0000000080005628 <virtio_disk_init>:
{
    80005628:	1101                	addi	sp,sp,-32
    8000562a:	ec06                	sd	ra,24(sp)
    8000562c:	e822                	sd	s0,16(sp)
    8000562e:	e426                	sd	s1,8(sp)
    80005630:	e04a                	sd	s2,0(sp)
    80005632:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005634:	00002597          	auipc	a1,0x2
    80005638:	01c58593          	addi	a1,a1,28 # 80007650 <etext+0x650>
    8000563c:	0001e517          	auipc	a0,0x1e
    80005640:	13450513          	addi	a0,a0,308 # 80023770 <disk+0x128>
    80005644:	d0afb0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005648:	100017b7          	lui	a5,0x10001
    8000564c:	4398                	lw	a4,0(a5)
    8000564e:	2701                	sext.w	a4,a4
    80005650:	747277b7          	lui	a5,0x74727
    80005654:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005658:	18f71063          	bne	a4,a5,800057d8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000565c:	100017b7          	lui	a5,0x10001
    80005660:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005662:	439c                	lw	a5,0(a5)
    80005664:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005666:	4709                	li	a4,2
    80005668:	16e79863          	bne	a5,a4,800057d8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000566c:	100017b7          	lui	a5,0x10001
    80005670:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005672:	439c                	lw	a5,0(a5)
    80005674:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005676:	16e79163          	bne	a5,a4,800057d8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000567a:	100017b7          	lui	a5,0x10001
    8000567e:	47d8                	lw	a4,12(a5)
    80005680:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005682:	554d47b7          	lui	a5,0x554d4
    80005686:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000568a:	14f71763          	bne	a4,a5,800057d8 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000568e:	100017b7          	lui	a5,0x10001
    80005692:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005696:	4705                	li	a4,1
    80005698:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000569a:	470d                	li	a4,3
    8000569c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000569e:	10001737          	lui	a4,0x10001
    800056a2:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800056a4:	c7ffe737          	lui	a4,0xc7ffe
    800056a8:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdafd7>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800056ac:	8ef9                	and	a3,a3,a4
    800056ae:	10001737          	lui	a4,0x10001
    800056b2:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    800056b4:	472d                	li	a4,11
    800056b6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800056b8:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    800056bc:	439c                	lw	a5,0(a5)
    800056be:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800056c2:	8ba1                	andi	a5,a5,8
    800056c4:	12078063          	beqz	a5,800057e4 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800056c8:	100017b7          	lui	a5,0x10001
    800056cc:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800056d0:	100017b7          	lui	a5,0x10001
    800056d4:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800056d8:	439c                	lw	a5,0(a5)
    800056da:	2781                	sext.w	a5,a5
    800056dc:	10079a63          	bnez	a5,800057f0 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800056e0:	100017b7          	lui	a5,0x10001
    800056e4:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    800056e8:	439c                	lw	a5,0(a5)
    800056ea:	2781                	sext.w	a5,a5
  if(max == 0)
    800056ec:	10078863          	beqz	a5,800057fc <virtio_disk_init+0x1d4>
  if(max < NUM)
    800056f0:	471d                	li	a4,7
    800056f2:	10f77b63          	bgeu	a4,a5,80005808 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    800056f6:	c08fb0ef          	jal	80000afe <kalloc>
    800056fa:	0001e497          	auipc	s1,0x1e
    800056fe:	f4e48493          	addi	s1,s1,-178 # 80023648 <disk>
    80005702:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005704:	bfafb0ef          	jal	80000afe <kalloc>
    80005708:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000570a:	bf4fb0ef          	jal	80000afe <kalloc>
    8000570e:	87aa                	mv	a5,a0
    80005710:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005712:	6088                	ld	a0,0(s1)
    80005714:	10050063          	beqz	a0,80005814 <virtio_disk_init+0x1ec>
    80005718:	0001e717          	auipc	a4,0x1e
    8000571c:	f3873703          	ld	a4,-200(a4) # 80023650 <disk+0x8>
    80005720:	0e070a63          	beqz	a4,80005814 <virtio_disk_init+0x1ec>
    80005724:	0e078863          	beqz	a5,80005814 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80005728:	6605                	lui	a2,0x1
    8000572a:	4581                	li	a1,0
    8000572c:	d76fb0ef          	jal	80000ca2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005730:	0001e497          	auipc	s1,0x1e
    80005734:	f1848493          	addi	s1,s1,-232 # 80023648 <disk>
    80005738:	6605                	lui	a2,0x1
    8000573a:	4581                	li	a1,0
    8000573c:	6488                	ld	a0,8(s1)
    8000573e:	d64fb0ef          	jal	80000ca2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005742:	6605                	lui	a2,0x1
    80005744:	4581                	li	a1,0
    80005746:	6888                	ld	a0,16(s1)
    80005748:	d5afb0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000574c:	100017b7          	lui	a5,0x10001
    80005750:	4721                	li	a4,8
    80005752:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005754:	4098                	lw	a4,0(s1)
    80005756:	100017b7          	lui	a5,0x10001
    8000575a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    8000575e:	40d8                	lw	a4,4(s1)
    80005760:	100017b7          	lui	a5,0x10001
    80005764:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005768:	649c                	ld	a5,8(s1)
    8000576a:	0007869b          	sext.w	a3,a5
    8000576e:	10001737          	lui	a4,0x10001
    80005772:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005776:	9781                	srai	a5,a5,0x20
    80005778:	10001737          	lui	a4,0x10001
    8000577c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005780:	689c                	ld	a5,16(s1)
    80005782:	0007869b          	sext.w	a3,a5
    80005786:	10001737          	lui	a4,0x10001
    8000578a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    8000578e:	9781                	srai	a5,a5,0x20
    80005790:	10001737          	lui	a4,0x10001
    80005794:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005798:	10001737          	lui	a4,0x10001
    8000579c:	4785                	li	a5,1
    8000579e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    800057a0:	00f48c23          	sb	a5,24(s1)
    800057a4:	00f48ca3          	sb	a5,25(s1)
    800057a8:	00f48d23          	sb	a5,26(s1)
    800057ac:	00f48da3          	sb	a5,27(s1)
    800057b0:	00f48e23          	sb	a5,28(s1)
    800057b4:	00f48ea3          	sb	a5,29(s1)
    800057b8:	00f48f23          	sb	a5,30(s1)
    800057bc:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800057c0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800057c4:	100017b7          	lui	a5,0x10001
    800057c8:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    800057cc:	60e2                	ld	ra,24(sp)
    800057ce:	6442                	ld	s0,16(sp)
    800057d0:	64a2                	ld	s1,8(sp)
    800057d2:	6902                	ld	s2,0(sp)
    800057d4:	6105                	addi	sp,sp,32
    800057d6:	8082                	ret
    panic("could not find virtio disk");
    800057d8:	00002517          	auipc	a0,0x2
    800057dc:	e8850513          	addi	a0,a0,-376 # 80007660 <etext+0x660>
    800057e0:	800fb0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    800057e4:	00002517          	auipc	a0,0x2
    800057e8:	e9c50513          	addi	a0,a0,-356 # 80007680 <etext+0x680>
    800057ec:	ff5fa0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    800057f0:	00002517          	auipc	a0,0x2
    800057f4:	eb050513          	addi	a0,a0,-336 # 800076a0 <etext+0x6a0>
    800057f8:	fe9fa0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    800057fc:	00002517          	auipc	a0,0x2
    80005800:	ec450513          	addi	a0,a0,-316 # 800076c0 <etext+0x6c0>
    80005804:	fddfa0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    80005808:	00002517          	auipc	a0,0x2
    8000580c:	ed850513          	addi	a0,a0,-296 # 800076e0 <etext+0x6e0>
    80005810:	fd1fa0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    80005814:	00002517          	auipc	a0,0x2
    80005818:	eec50513          	addi	a0,a0,-276 # 80007700 <etext+0x700>
    8000581c:	fc5fa0ef          	jal	800007e0 <panic>

0000000080005820 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005820:	7159                	addi	sp,sp,-112
    80005822:	f486                	sd	ra,104(sp)
    80005824:	f0a2                	sd	s0,96(sp)
    80005826:	eca6                	sd	s1,88(sp)
    80005828:	e8ca                	sd	s2,80(sp)
    8000582a:	e4ce                	sd	s3,72(sp)
    8000582c:	e0d2                	sd	s4,64(sp)
    8000582e:	fc56                	sd	s5,56(sp)
    80005830:	f85a                	sd	s6,48(sp)
    80005832:	f45e                	sd	s7,40(sp)
    80005834:	f062                	sd	s8,32(sp)
    80005836:	ec66                	sd	s9,24(sp)
    80005838:	1880                	addi	s0,sp,112
    8000583a:	8a2a                	mv	s4,a0
    8000583c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000583e:	00c52c83          	lw	s9,12(a0)
    80005842:	001c9c9b          	slliw	s9,s9,0x1
    80005846:	1c82                	slli	s9,s9,0x20
    80005848:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000584c:	0001e517          	auipc	a0,0x1e
    80005850:	f2450513          	addi	a0,a0,-220 # 80023770 <disk+0x128>
    80005854:	b7afb0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    80005858:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000585a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000585c:	0001eb17          	auipc	s6,0x1e
    80005860:	decb0b13          	addi	s6,s6,-532 # 80023648 <disk>
  for(int i = 0; i < 3; i++){
    80005864:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005866:	0001ec17          	auipc	s8,0x1e
    8000586a:	f0ac0c13          	addi	s8,s8,-246 # 80023770 <disk+0x128>
    8000586e:	a8b9                	j	800058cc <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005870:	00fb0733          	add	a4,s6,a5
    80005874:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005878:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000587a:	0207c563          	bltz	a5,800058a4 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    8000587e:	2905                	addiw	s2,s2,1
    80005880:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005882:	05590963          	beq	s2,s5,800058d4 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005886:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005888:	0001e717          	auipc	a4,0x1e
    8000588c:	dc070713          	addi	a4,a4,-576 # 80023648 <disk>
    80005890:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005892:	01874683          	lbu	a3,24(a4)
    80005896:	fee9                	bnez	a3,80005870 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005898:	2785                	addiw	a5,a5,1
    8000589a:	0705                	addi	a4,a4,1
    8000589c:	fe979be3          	bne	a5,s1,80005892 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    800058a0:	57fd                	li	a5,-1
    800058a2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800058a4:	01205d63          	blez	s2,800058be <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    800058a8:	f9042503          	lw	a0,-112(s0)
    800058ac:	d07ff0ef          	jal	800055b2 <free_desc>
      for(int j = 0; j < i; j++)
    800058b0:	4785                	li	a5,1
    800058b2:	0127d663          	bge	a5,s2,800058be <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    800058b6:	f9442503          	lw	a0,-108(s0)
    800058ba:	cf9ff0ef          	jal	800055b2 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800058be:	85e2                	mv	a1,s8
    800058c0:	0001e517          	auipc	a0,0x1e
    800058c4:	da050513          	addi	a0,a0,-608 # 80023660 <disk+0x18>
    800058c8:	e72fc0ef          	jal	80001f3a <sleep>
  for(int i = 0; i < 3; i++){
    800058cc:	f9040613          	addi	a2,s0,-112
    800058d0:	894e                	mv	s2,s3
    800058d2:	bf55                	j	80005886 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800058d4:	f9042503          	lw	a0,-112(s0)
    800058d8:	00451693          	slli	a3,a0,0x4

  if(write)
    800058dc:	0001e797          	auipc	a5,0x1e
    800058e0:	d6c78793          	addi	a5,a5,-660 # 80023648 <disk>
    800058e4:	00a50713          	addi	a4,a0,10
    800058e8:	0712                	slli	a4,a4,0x4
    800058ea:	973e                	add	a4,a4,a5
    800058ec:	01703633          	snez	a2,s7
    800058f0:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800058f2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800058f6:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800058fa:	6398                	ld	a4,0(a5)
    800058fc:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800058fe:	0a868613          	addi	a2,a3,168
    80005902:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005904:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005906:	6390                	ld	a2,0(a5)
    80005908:	00d605b3          	add	a1,a2,a3
    8000590c:	4741                	li	a4,16
    8000590e:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005910:	4805                	li	a6,1
    80005912:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80005916:	f9442703          	lw	a4,-108(s0)
    8000591a:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000591e:	0712                	slli	a4,a4,0x4
    80005920:	963a                	add	a2,a2,a4
    80005922:	058a0593          	addi	a1,s4,88
    80005926:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005928:	0007b883          	ld	a7,0(a5)
    8000592c:	9746                	add	a4,a4,a7
    8000592e:	40000613          	li	a2,1024
    80005932:	c710                	sw	a2,8(a4)
  if(write)
    80005934:	001bb613          	seqz	a2,s7
    80005938:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000593c:	00166613          	ori	a2,a2,1
    80005940:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005944:	f9842583          	lw	a1,-104(s0)
    80005948:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000594c:	00250613          	addi	a2,a0,2
    80005950:	0612                	slli	a2,a2,0x4
    80005952:	963e                	add	a2,a2,a5
    80005954:	577d                	li	a4,-1
    80005956:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000595a:	0592                	slli	a1,a1,0x4
    8000595c:	98ae                	add	a7,a7,a1
    8000595e:	03068713          	addi	a4,a3,48
    80005962:	973e                	add	a4,a4,a5
    80005964:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005968:	6398                	ld	a4,0(a5)
    8000596a:	972e                	add	a4,a4,a1
    8000596c:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005970:	4689                	li	a3,2
    80005972:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005976:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000597a:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    8000597e:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005982:	6794                	ld	a3,8(a5)
    80005984:	0026d703          	lhu	a4,2(a3)
    80005988:	8b1d                	andi	a4,a4,7
    8000598a:	0706                	slli	a4,a4,0x1
    8000598c:	96ba                	add	a3,a3,a4
    8000598e:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005992:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005996:	6798                	ld	a4,8(a5)
    80005998:	00275783          	lhu	a5,2(a4)
    8000599c:	2785                	addiw	a5,a5,1
    8000599e:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800059a2:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800059a6:	100017b7          	lui	a5,0x10001
    800059aa:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800059ae:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800059b2:	0001e917          	auipc	s2,0x1e
    800059b6:	dbe90913          	addi	s2,s2,-578 # 80023770 <disk+0x128>
  while(b->disk == 1) {
    800059ba:	4485                	li	s1,1
    800059bc:	01079a63          	bne	a5,a6,800059d0 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    800059c0:	85ca                	mv	a1,s2
    800059c2:	8552                	mv	a0,s4
    800059c4:	d76fc0ef          	jal	80001f3a <sleep>
  while(b->disk == 1) {
    800059c8:	004a2783          	lw	a5,4(s4)
    800059cc:	fe978ae3          	beq	a5,s1,800059c0 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    800059d0:	f9042903          	lw	s2,-112(s0)
    800059d4:	00290713          	addi	a4,s2,2
    800059d8:	0712                	slli	a4,a4,0x4
    800059da:	0001e797          	auipc	a5,0x1e
    800059de:	c6e78793          	addi	a5,a5,-914 # 80023648 <disk>
    800059e2:	97ba                	add	a5,a5,a4
    800059e4:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800059e8:	0001e997          	auipc	s3,0x1e
    800059ec:	c6098993          	addi	s3,s3,-928 # 80023648 <disk>
    800059f0:	00491713          	slli	a4,s2,0x4
    800059f4:	0009b783          	ld	a5,0(s3)
    800059f8:	97ba                	add	a5,a5,a4
    800059fa:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800059fe:	854a                	mv	a0,s2
    80005a00:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005a04:	bafff0ef          	jal	800055b2 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005a08:	8885                	andi	s1,s1,1
    80005a0a:	f0fd                	bnez	s1,800059f0 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005a0c:	0001e517          	auipc	a0,0x1e
    80005a10:	d6450513          	addi	a0,a0,-668 # 80023770 <disk+0x128>
    80005a14:	a52fb0ef          	jal	80000c66 <release>
}
    80005a18:	70a6                	ld	ra,104(sp)
    80005a1a:	7406                	ld	s0,96(sp)
    80005a1c:	64e6                	ld	s1,88(sp)
    80005a1e:	6946                	ld	s2,80(sp)
    80005a20:	69a6                	ld	s3,72(sp)
    80005a22:	6a06                	ld	s4,64(sp)
    80005a24:	7ae2                	ld	s5,56(sp)
    80005a26:	7b42                	ld	s6,48(sp)
    80005a28:	7ba2                	ld	s7,40(sp)
    80005a2a:	7c02                	ld	s8,32(sp)
    80005a2c:	6ce2                	ld	s9,24(sp)
    80005a2e:	6165                	addi	sp,sp,112
    80005a30:	8082                	ret

0000000080005a32 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005a32:	1101                	addi	sp,sp,-32
    80005a34:	ec06                	sd	ra,24(sp)
    80005a36:	e822                	sd	s0,16(sp)
    80005a38:	e426                	sd	s1,8(sp)
    80005a3a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005a3c:	0001e497          	auipc	s1,0x1e
    80005a40:	c0c48493          	addi	s1,s1,-1012 # 80023648 <disk>
    80005a44:	0001e517          	auipc	a0,0x1e
    80005a48:	d2c50513          	addi	a0,a0,-724 # 80023770 <disk+0x128>
    80005a4c:	982fb0ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005a50:	100017b7          	lui	a5,0x10001
    80005a54:	53b8                	lw	a4,96(a5)
    80005a56:	8b0d                	andi	a4,a4,3
    80005a58:	100017b7          	lui	a5,0x10001
    80005a5c:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80005a5e:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005a62:	689c                	ld	a5,16(s1)
    80005a64:	0204d703          	lhu	a4,32(s1)
    80005a68:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80005a6c:	04f70663          	beq	a4,a5,80005ab8 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005a70:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005a74:	6898                	ld	a4,16(s1)
    80005a76:	0204d783          	lhu	a5,32(s1)
    80005a7a:	8b9d                	andi	a5,a5,7
    80005a7c:	078e                	slli	a5,a5,0x3
    80005a7e:	97ba                	add	a5,a5,a4
    80005a80:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005a82:	00278713          	addi	a4,a5,2
    80005a86:	0712                	slli	a4,a4,0x4
    80005a88:	9726                	add	a4,a4,s1
    80005a8a:	01074703          	lbu	a4,16(a4)
    80005a8e:	e321                	bnez	a4,80005ace <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005a90:	0789                	addi	a5,a5,2
    80005a92:	0792                	slli	a5,a5,0x4
    80005a94:	97a6                	add	a5,a5,s1
    80005a96:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005a98:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005a9c:	ceafc0ef          	jal	80001f86 <wakeup>

    disk.used_idx += 1;
    80005aa0:	0204d783          	lhu	a5,32(s1)
    80005aa4:	2785                	addiw	a5,a5,1
    80005aa6:	17c2                	slli	a5,a5,0x30
    80005aa8:	93c1                	srli	a5,a5,0x30
    80005aaa:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005aae:	6898                	ld	a4,16(s1)
    80005ab0:	00275703          	lhu	a4,2(a4)
    80005ab4:	faf71ee3          	bne	a4,a5,80005a70 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005ab8:	0001e517          	auipc	a0,0x1e
    80005abc:	cb850513          	addi	a0,a0,-840 # 80023770 <disk+0x128>
    80005ac0:	9a6fb0ef          	jal	80000c66 <release>
}
    80005ac4:	60e2                	ld	ra,24(sp)
    80005ac6:	6442                	ld	s0,16(sp)
    80005ac8:	64a2                	ld	s1,8(sp)
    80005aca:	6105                	addi	sp,sp,32
    80005acc:	8082                	ret
      panic("virtio_disk_intr status");
    80005ace:	00002517          	auipc	a0,0x2
    80005ad2:	c4a50513          	addi	a0,a0,-950 # 80007718 <etext+0x718>
    80005ad6:	d0bfa0ef          	jal	800007e0 <panic>
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0)
    80006010:	02253823          	sd	sp,48(a0)
    80006014:	02353c23          	sd	gp,56(a0)
    80006018:	04453023          	sd	tp,64(a0)
    8000601c:	04553423          	sd	t0,72(a0)
    80006020:	04653823          	sd	t1,80(a0)
    80006024:	04753c23          	sd	t2,88(a0)
    80006028:	f120                	sd	s0,96(a0)
    8000602a:	f524                	sd	s1,104(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
    8000602e:	e150                	sd	a2,128(a0)
    80006030:	e554                	sd	a3,136(a0)
    80006032:	e958                	sd	a4,144(a0)
    80006034:	ed5c                	sd	a5,152(a0)
    80006036:	0b053023          	sd	a6,160(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
    80006046:	0d453023          	sd	s4,192(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
    80006056:	0f853023          	sd	s8,224(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
    80006066:	11c53023          	sd	t3,256(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
    80006072:	11f53c23          	sd	t6,280(a0)
    80006076:	140022f3          	csrr	t0,sscratch
    8000607a:	06553823          	sd	t0,112(a0)
    8000607e:	00853103          	ld	sp,8(a0)
    80006082:	02053203          	ld	tp,32(a0)
    80006086:	01053283          	ld	t0,16(a0)
    8000608a:	00053303          	ld	t1,0(a0)
    8000608e:	12000073          	sfence.vma
    80006092:	18031073          	csrw	satp,t1
    80006096:	12000073          	sfence.vma
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
    8000609c:	12000073          	sfence.vma
    800060a0:	18051073          	csrw	satp,a0
    800060a4:	12000073          	sfence.vma
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0)
    800060b4:	03053103          	ld	sp,48(a0)
    800060b8:	03853183          	ld	gp,56(a0)
    800060bc:	04053203          	ld	tp,64(a0)
    800060c0:	04853283          	ld	t0,72(a0)
    800060c4:	05053303          	ld	t1,80(a0)
    800060c8:	05853383          	ld	t2,88(a0)
    800060cc:	7120                	ld	s0,96(a0)
    800060ce:	7524                	ld	s1,104(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
    800060d2:	6150                	ld	a2,128(a0)
    800060d4:	6554                	ld	a3,136(a0)
    800060d6:	6958                	ld	a4,144(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
    800060da:	0a053803          	ld	a6,160(a0)
    800060de:	0a853883          	ld	a7,168(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
    80006112:	11053f03          	ld	t5,272(a0)
    80006116:	11853f83          	ld	t6,280(a0)
    8000611a:	7928                	ld	a0,112(a0)
    8000611c:	10200073          	sret
	...
