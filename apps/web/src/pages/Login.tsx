import * as z from 'zod'

const Login = () => {

  /****************** zod start ********************/
  // const foo = z.literal('foo')
  // console.log(foo.safeParse('ddd'))
  // console.log(foo.parse('foo'))

  // const schema = z.templateLiteral(['hello ', z.string(), '!'])
  // console.log(schema.safeParse('hello  world! sdsd'))

  // const n1 = z.number().multipleOf(5)
  // console.log(n1.safeParse(6))
  // console.log(n1.safeParse(10))

  // const boo1 = z.boolean()
  // console.log(boo1.safeParse(true))
  // console.log(boo1.safeParse(0))
  // console.log(boo1.safeParse(1))
  // console.log(boo1.safeParse(false))

  // const c1 = z.coerce.boolean().safeParse("false")
  // console.log(c1);

  // const fish = ["Salmon", "Tuna", "Trout"] as const
  // // eslint-disable-next-line @typescript-eslint/no-unused-vars
  // const FishEnum = z.enum(fish)
  // type FE = z.infer<typeof FishEnum>

  // const test: FE = "Salmon"
  // console.log(test);

  const dog = z.strictObject({
    name: z.string()
  })

  console.log(dog.safeParse({ name: 'beibei', age: 2 }))
  

  /****************** zod end ********************/

  return <div className="h-screen w-full flex items-center justify-center">
    <div className="w-[560px] h-[480px] overflow-auto border-2 rounded-lg">
      <h2>登录</h2>
      
    </div>
  </div>
}

export default Login